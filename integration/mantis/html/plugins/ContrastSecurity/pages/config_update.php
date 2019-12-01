<?php

    form_security_validate('plugin_ContrastSecurity_config_update');

    auth_reauthenticate();
    access_ensure_global_level(config_get('manage_plugin_threshold'));

    $teamserver_url = gpc_get_string('teamserver_url');
    $org_id = gpc_get_string('org_id');
    $api_key = gpc_get_string('api_key');
    $auth_header = gpc_get_string('auth_header');
    $vul_issues = gpc_get_bool('vul_issues');
    $lib_issues = gpc_get_bool('lib_issues');

    # /Contrast/api/ng/dd0c161a-e5b3-40fd-b837-2d3a362d3975/applications/
    $url = sprintf('%s/api/ng/%s/applications', $teamserver_url, $org_id);
    $curl = curl_init();
    curl_setopt($curl, CURLOPT_URL, $url);
    curl_setopt($curl, CURLOPT_HTTPHEADER, array(
        'Authorization: ' . $auth_header,
        'API-Key: ' . $api_key,
        'Accept: application/json',
        'Content-Type: application/json',
    ));
    curl_setopt($curl, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($curl, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($curl, CURLOPT_CONNECTTIMEOUT, 10);
    $result = curl_exec($curl);
    if (!$result) {
        trigger_error(plugin_lang_get('connect_error'), ERROR);
    }
    curl_close($curl);
    $result_json = json_decode($result, true);
    if ($result_json['success'] != true) {
        trigger_error(plugin_lang_get('connect_auth_error'), ERROR);
    }
    plugin_config_set('teamserver_url', $teamserver_url);
    plugin_config_set('org_id', $org_id);
    plugin_config_set('api_key', $api_key);
    plugin_config_set('auth_header', $auth_header);
    plugin_config_set('vul_issues', $vul_issues);
    plugin_config_set('lib_issues', $lib_issues);

    form_security_purge('plugin_ContrastSecurity_config_update');
    print_successful_redirect(plugin_page('config', true));

