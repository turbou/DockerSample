<?php

require_api('authentication_api.php');
require_api('user_api.php');
require_api('api_token_api.php');

$t_restlocal_dir = __DIR__ . '/core/';
require_once( $t_restlocal_dir . 'MyAuthMiddleware.php' );

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
            $t_user_id = api_token_get_user('poqQoA_5w_iOKo21LrP3VCPWwd-z4Lzm');
            if( $t_user_id !== false ) {
                $t_api_token = 'poqQoA_5w_iOKo21LrP3VCPWwd-z4Lzm';
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
                $t_app->post( '/{key}/issue', [$t_plugin, 'rest_issue_add']);
            }
        )->add(new MyAuthMiddleware);
    }
    /**
     * A method that does the work to handle getting an issue via REST API.
     *
     * @param \Slim\Http\Request $p_request   The request.
     * @param \Slim\Http\Response $p_response The response.
     * @param array $p_args Arguments
     * @return \Slim\Http\Response The augmented response.
     */
    #function rest_issue_get( \Slim\Http\Request $p_request, \Slim\Http\Response $p_response, array $p_args ) {
    function rest_auth_test($p_request, $p_response, array $p_args) {
    	$t_key = isset($p_args['key']) ? $p_args['key'] : $p_request->getParam('key');
        return $p_response->withHeader(HTTP_STATUS_SUCCESS, "Success");

#    	if( !is_blank( $t_issue_id ) ) {
#    		# Get Issue By Id
#    
#    		# Username and password below are ignored, since middleware already done the auth.
#    		$t_issue = mc_issue_get( /* username */ '', /* password */ '', $t_issue_id );
#    		ApiObjectFactory::throwIfFault( $t_issue );
#    
#    		$t_result = array( 'issues' => array( $t_issue ) );
#    	} else {
#    		$t_page_number = $p_request->getParam( 'page', 1 );
#    		$t_page_size = $p_request->getParam( 'page_size', 50 );
#    
#    		# Get a set of issues
#    		$t_project_id = (int)$p_request->getParam( 'project_id', ALL_PROJECTS );
#    		if( $t_project_id != ALL_PROJECTS && !project_exists( $t_project_id ) ) {
#    			$t_result = null;
#    			$t_message = "Project '$t_project_id' doesn't exist";
#    			$p_response = $p_response->withStatus( HTTP_STATUS_NOT_FOUND, $t_message );
#    		} else {
#    			$t_filter_id = trim( $p_request->getParam( 'filter_id', '' ) );
#    
#    			if( !empty( $t_filter_id ) ) {
#    				$t_issues = mc_filter_get_issues(
#    					'', '', $t_project_id, $t_filter_id, $t_page_number, $t_page_size );
#    			} else {
#    				$t_issues = mc_filter_get_issues(
#    					'', '', $t_project_id, FILTER_STANDARD_ANY, $t_page_number, $t_page_size );
#    			}
#    
#    			$t_result = array( 'issues' => $t_issues );
#    		}
#    	}
#    
#    	$t_etag = mc_issue_hash( $t_issue_id, $t_result );
#    	if( $p_request->hasHeader( HEADER_IF_NONE_MATCH ) ) {
#    		$t_match_etag = $p_request->getHeaderLine( HEADER_IF_NONE_MATCH );
#    		if( $t_etag == $t_match_etag ) {
#    			return $p_response->withStatus( HTTP_STATUS_NOT_MODIFIED, 'Not Modified' )
#    				->withHeader( HEADER_ETAG, $t_etag );
#    		}
#    	}
#    
#    	if( $t_result !== null ) {
#    		$p_response = $p_response->withStatus( HTTP_STATUS_SUCCESS )->withJson( $t_result );
#    	}
#
#    	return $p_response->withHeader( HEADER_ETAG, $t_etag );
    }
    
    /**
     * Create an issue from a POST to the issues url.
     *
     * @param \Slim\Http\Request $p_request   The request.
     * @param \Slim\Http\Response $p_response The response.
     * @param array $p_args Arguments
     * @return \Slim\Http\Response The augmented response.
     */
    function rest_issue_add( \Slim\Http\Request $p_request, \Slim\Http\Response $p_response, array $p_args ) {
            $t_issue = $p_request->getParsedBody();
    
            if( isset( $t_issue['files'] ) ) {
                    $t_issue['files'] = files_base64_to_temp( $t_issue['files'] );
            }
    
            $t_data = array( 'payload' => array( 'issue' => $t_issue ) );
            $t_command = new IssueAddCommand( $t_data );
            $t_result = $t_command->execute();
            $t_issue_id = (int)$t_result['issue_id'];
    
            $t_created_issue = mc_issue_get( /* username */ '', /* password */ '', $t_issue_id );
    
            return $p_response->withStatus( HTTP_STATUS_CREATED, "Issue Created with id $t_issue_id" )->
                    withJson( array( 'issue' => $t_created_issue ) );
    }
}


