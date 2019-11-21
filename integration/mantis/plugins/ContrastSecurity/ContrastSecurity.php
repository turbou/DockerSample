<?php

class ContrastSecurityPlugin extends MantisPlugin {
    public function register() {
        error_log('register');
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
        error_log('init');
        $t_inc = get_include_path();
        error_log($t_inc);
        $t_core = config_get_global('core_path');
        error_log($t_core);
        $t_path = config_get_global('plugin_path'). plugin_get_current() . DIRECTORY_SEPARATOR . 'core'. DIRECTORY_SEPARATOR;
        if (strstr($t_inc, $t_core) == false) {
            error_log($t_inc . PATH_SEPARATOR . $t_core . PATH_SEPARATOR . $t_path);
            set_include_path($t_inc . PATH_SEPARATOR . $t_core . PATH_SEPARATOR . $t_path);
        } else {
            error_log($t_inc .  PATH_SEPARATOR . $t_path);
            set_include_path($t_inc .  PATH_SEPARATOR . $t_path);
        }
    }

    function config() {
        error_log('config');
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
        error_log('hooks');
        error_log(var_dump(parent::hooks()));
        return parent::hooks() + array(
            'EVENT_REST_API_ROUTES' => 'routes',
        );
    }
    
    public function routes($p_event_name, $p_event_args) {
        error_log('routes');
        $t_app = $p_event_args['app'];
        $t_plugin = $this;
        $t_app->group(
            plugin_route_group(),
            function() use ( $t_app, $t_plugin ) {
                #$t_app->delete( '/{id}/token', [$t_plugin, 'route_token_revoke'] );
                #$t_app->post( '/{id}/webhook', [$t_plugin, 'route_webhook'] );
                $t_app->get('/hello/{name}', function ($request, $response, $args) {
                    #echo "Hello, " . $args['name'] . "\r\n";
                    echo "Hello, " . $args['name'];
                }); 
            }
        );
    }

    #public function route_token_revoke($p_request, $p_response, $p_args) {
    #    return $p_response->withStatus( HTTP_STATUS_NO_CONTENT );
    #}
}

