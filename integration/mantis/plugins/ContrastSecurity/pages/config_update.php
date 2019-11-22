<?php

    form_security_validate('plugin_ContrastSecurity_config_update');

    auth_reauthenticate();
    access_ensure_global_level(config_get('manage_plugin_threshold'));

    $teamserver_url = gpc_get_string('teamserver_url');
    $api_key = gpc_get_string('api_key');
    $auth_header = gpc_get_string('auth_header');
    plugin_config_set('teamserver_url', $teamserver_url);
    plugin_config_set('api_key', $api_key);
    plugin_config_set('auth_header', $auth_header);

    form_security_purge('plugin_ContrastSecurity_config_update');

    print_successful_redirect(plugin_page('config', true));

