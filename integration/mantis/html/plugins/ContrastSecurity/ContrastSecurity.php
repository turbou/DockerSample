<?php

require_api('authentication_api.php');
require_api('user_api.php');
require_api('api_token_api.php');

class ContrastSecurityPlugin extends MantisPlugin {
    public function register() {
        $this->name = plugin_lang_get("title");
        $this->description = plugin_lang_get("description");
        $this->page = 'config';

        $this->version = "1.0.0";
        $this->requires = array(
            "MantisCore" => "2.0.0",
        );

        $this->author = "Taka Shiozaki";
        $this->contact = "taka.shiozaki@contrastsecurity.com";
        $this->url = "https://github.com/turbou/ContrastSecurity/tree/master/integration/mantis/plugins/ContrastSecurity";
    }

    function init() {
        $t_inc = get_include_path();
        $t_core = config_get_global('core_path');
        $t_path = config_get_global('plugin_path'). plugin_get_current() . DIRECTORY_SEPARATOR . 'core'. DIRECTORY_SEPARATOR;
        if (strstr($t_inc, $t_core) == false) {
            set_include_path($t_inc . PATH_SEPARATOR . $t_core . PATH_SEPARATOR . $t_path);
        } else {
            set_include_path($t_inc .  PATH_SEPARATOR . $t_path);
        }
    }

    function config() {
        return array(
            'teamserver_url' => '',
            'api_key' => '',
            'auth_header' => ''
        );
    }

    public function hooks() {
        return parent::hooks() + array(
            'EVENT_REST_API_ROUTES' => 'routes',
            'EVENT_UPDATE_BUG' => 'bug_update',
        );
    }
    
    public function routes($p_event_name, $p_event_args) {
        $t_app = $p_event_args['app'];
        $t_app->add(function($req, $res, $next) {
            $path = $req->getUri()->getPath();
            #error_log('path: ' . $path);
            $is_exist_key = preg_match('/^plugins\/ContrastSecurity\/(\w+)/', $path, $match);
            if(!$is_exist_key) {
                return $next($req, $res);
            }
            #error_log('key: ' . $match[1]);
            $token = $match[1];
            $t_user_id = api_token_get_user($token);
            if( $t_user_id !== false ) {
                $t_api_token = $token;
            }
            if( $t_user_id === false ) { 
                return $res->withStatus(HTTP_STATUS_FORBIDDEN, 'API token not found');
            } 
            # use api token
            $t_login_method = LOGIN_METHOD_API_TOKEN;
            $t_password = $t_api_token;
            $t_username = user_get_username($t_user_id);
            if( mci_check_login($t_username, $t_password) === false) {
                return $res->withStatus(HTTP_STATUS_FORBIDDEN, 'Access denied');
            }
            $res->getBody()->write($t_username . " middleware #2\n");
            return $next($req, $res);
        });
        $t_plugin = $this;
        $t_app->group(plugin_route_group(), function() use ($t_app, $t_plugin) {
            $t_app->get('/hello/{name}', function ($request, $response, $args) {
                echo "Hello, " . $args['name'] . "!!\r\n";
            }); 
            $t_app->get( '/{key}/test', [$t_plugin, 'rest_auth_test']);
            $t_app->post( '/{key}/test', [$t_plugin, 'rest_auth_test']);
            $t_app->post( '/{key}/issues', [$t_plugin, 'rest_issue_add']);
        });
    }
    /**
     * A method that does the work to handle getting an issue via REST API.
     *
     * @param \Slim\Http\Request $p_request   The request.
     * @param \Slim\Http\Response $p_response The response.
     * @param array $p_args Arguments
     * @return \Slim\Http\Response The augmented response.
     */
    function rest_auth_test(\Slim\Http\Request $p_request, \Slim\Http\Response $p_response, array $p_args) {
        plugin_push_current('ContrastSecurity');
        error_log('rest_auth_test');
        $t_key = isset($p_args['key']) ? $p_args['key'] : $p_request->getParam('key');
        error_log(plugin_config_get('teamserver_url', ''));
        error_log(plugin_config_get('api_key', ''));
        error_log(plugin_config_get('auth_header', ''));
        return $p_response->withHeader(HTTP_STATUS_SUCCESS, "Success");
    }
    
    /**
     * Create an issue from a POST to the issues url.
     *
     * @param \Slim\Http\Request $p_request   The request.
     * @param \Slim\Http\Response $p_response The response.
     * @param array $p_args Arguments
     * @return \Slim\Http\Response The augmented response.
     */
    function rest_issue_add(\Slim\Http\Request $p_request, \Slim\Http\Response $p_response, array $p_args) {
        $contentType = $p_request->getContentType();
        #error_log($contentType);
        #$t_issue = $p_request->getParsedBody();
        $json_data = $p_request->getBody();
        error_log('json_data: ' . $json_data);
        $t_issue = json_decode($json_data, true);
        error_log('t_issue: ' . var_dump($t_issue));
        if ($t_issue["applicationName"] == "ContrastTestApplication") {
            return $p_response->withHeader(HTTP_STATUS_SUCCESS, "Success");
        }
        #error_log(var_dump($t_issue));
        #error_log($t_issue['description']);
        $is_exist = preg_match('/index.html#\/(.+)\/applications\/(.+)\/vulns\/(.+)\) was found in/', $t_issue['description'], $match);
        if ($is_exist) {
            plugin_push_current('ContrastSecurity');
            $teamserver_url = plugin_config_get('teamserver_url');
            $org_id = $match[1];
            $app_id = $match[2];
            $vul_id = $match[3];
            # /Contrast/api/ng/[ORG_ID]/traces/[APP_ID]/trace/[VUL_ID]
            $url = sprintf('%s/api/ng/%s/traces/%s/trace/%s', $teamserver_url, $org_id, $app_id, $vul_id);
            #error_log($url);
            $get_data = callAPI('GET', $url, false);
            $vuln_json = json_decode($get_data, true);
            $summary = $vuln_json["trace"]["title"];
            $description = $t_issue['description'];
            $t_issue['summary'] = $summary;
            $t_issue['custom_fields'] = array('{"field": {"id": 1, "name": "org_id"}, "value":' . $org_id . '}');
            #error_log('custom_fields add: ' . json_encode($t_issue));
            plugin_pop_current('ContrastSecurity');
        } else {
            error_log('nonmatch');
        }

        $t_data = array('payload'=>array('issue' => $t_issue));
        $t_command = new IssueAddCommand($t_data);
        $t_result = $t_command->execute();
        error_log(var_dump($t_result));
        #$t_issue_id = (int)$t_result['issue_id'];
        #$t_created_issue = mc_issue_get( /* username */ '', /* password */ '', $t_issue_id );
        #return $p_response->withStatus( HTTP_STATUS_CREATED, "Issue Created with id $t_issue_id" )->withJson( array( 'issue' => $t_created_issue ) );
        return $p_response->withHeader(HTTP_STATUS_SUCCESS, "Success");
    }

    public function bug_update($p_event_name, $t_existing_bug, $t_updated_bug) {
        error_log('event_name: ' . $p_event_name);
        error_log('status: ' . $t_existing_bug->status . ' -> ' . $t_updated_bug->status);
        plugin_push_current('ContrastSecurity');
        $teamserver_url = plugin_config_get('teamserver_url');
        $org_id = 'dd0c161a-e5b3-40fd-b837-2d3a362d3975';
        # /Contrast/api/ng/[ORG_ID]/orgtraces/mark
        # {traces: ["6J22-DQ96-VN03-LFTD"], status: "Confirmed", note: "test."}
        $url = sprintf('%s/api/ng/%s/orgtraces/mark', $teamserver_url, $org_id);
        $t_data = array('traces' => array('28RR-84L2-D69W-K9JL'), 'status' => 'Reported', 'note' => 'mantisbt.');
        #error_log($url);
        #error_log(json_encode($t_data));
        $put_result = callAPI('PUT', $url, json_encode($t_data));
        error_log($put_result);
        $result = json_decode($put_result, true);
        plugin_pop_current('ContrastSecurity');
    }
}

function callAPI($method, $url, $data){
   $curl = curl_init();

   switch ($method){
      case "POST":
         curl_setopt($curl, CURLOPT_POST, 1);
         if ($data)
            curl_setopt($curl, CURLOPT_POSTFIELDS, $data);
         break;
      case "PUT":
         curl_setopt($curl, CURLOPT_CUSTOMREQUEST, "PUT");
         if ($data)
            curl_setopt($curl, CURLOPT_POSTFIELDS, $data);			 					
         break;
      default:
         if ($data)
            $url = sprintf("%s?%s", $url, http_build_query($data));
   }

   // OPTIONS:
   $api_key = plugin_config_get('api_key');
   $auth_header = plugin_config_get('auth_header');
   curl_setopt($curl, CURLOPT_URL, $url);
   curl_setopt($curl, CURLOPT_HTTPHEADER, array(
      'Authorization: ' . $auth_header,
      'API-Key: ' . $api_key,
      'Accept: application/json',
      'Content-Type: application/json',
   ));
   curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
   curl_setopt($curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);

   // EXECUTE:
   $result = curl_exec($curl);
   if(!$result){die("Connection Failure");}
   curl_close($curl);
   return $result;
}

