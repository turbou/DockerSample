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
            'issues'  => ON,
            'auth_issues'  => ON,
            'issues_count'  => ON,
            'issues_countbadge'  => ON,
            'version'  => ON,
            'versionbadge'  => ON,
            'next_version_type' => 1,
            'api_user' => '',
            'api_token' => ''
        );
    }

    public function hooks() {
        return parent::hooks() + array(
            'EVENT_REST_API_ROUTES' => 'routes',
        );
    }
    
    public function routes($p_event_name, $p_event_args) {
        $t_app = $p_event_args['app'];
        $t_app->add(function($req, $res, $next) {
            $path = $req->getUri()->getPath();
            error_log('path: ' . $path);
            $is_exist_key = preg_match('/^plugins\/ContrastSecurity\/(\w+)/', $path, $match);
            if(!$is_exist_key) {
                return $next($req, $res);
            }
            error_log('key: ' . $match[1]);
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
                $t_app->post( '/{key}/issues', [$t_plugin, 'rest_issue_add']);
            }
        );
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
        error_log('rest_auth_test');
        $t_key = isset($p_args['key']) ? $p_args['key'] : $p_request->getParam('key');
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
        $t_issue = $p_request->getParsedBody();

        $t_data = array('payload' => array('issue' => $t_issue));
        #error_log(var_dump($t_data));
        $t_command = new IssueAddCommand($t_data);
        #error_log(var_dump($t_command));
        $t_result = $t_command->execute();
        #error_log(var_dump($t_result));
        $t_issue_id = (int)$t_result['issue_id'];

        $t_created_issue = mc_issue_get( /* username */ '', /* password */ '', $t_issue_id );

        return $p_response->withStatus( HTTP_STATUS_CREATED, "Issue Created with id $t_issue_id" )->
           withJson( array( 'issue' => $t_created_issue ) );
    }
}

