<?php

auth_reauthenticate( );
access_ensure_global_level( config_get( 'manage_plugin_threshold' ) );

$t_title = str_replace( '%%project%%', project_get_name( $t_project_id ), plugin_lang_get( 'config_page_title' ) );
layout_page_header($t_title);

layout_page_begin('manage_overview_page.php');
print_manage_menu('manage_plugin_page.php');

?>

<div class="col-md-12 col-xs-12">
  <div class="space-10"></div>
  <h3><?php echo plugin_lang_get('config_section_general') ?></h3>
</div>
<form name="plugins_releases" method="post" action="<?php echo plugin_page('config_update') ?>">
<?php echo form_security_field('plugin_ContrastSecurity_config_update') ?>
  <div class="col-md-12 col-xs-12">
    <div class="form-container" >
      <div class="widget-box widget-color-blue2">
        <div class="widget-header widget-header-small">
          <h4 class="widget-title lighter"><?php echo plugin_lang_get('config_section_connect') ?></h4>
        </div>
        <div class="widget-body">
          <div class="widget-main no-padding">
            <div class="table-responsive">
              <table class="table table-bordered table-condensed table-striped">
                <tr <?php echo helper_alternate_class() ?>>
                  <td class="category" width="200"><?php echo plugin_lang_get('teamserver_url'); ?></td>
                  <td>
                    <input name="teamserver_url" size="50" placeholder="http://XXX.XXX.XXX.XXX:8080/Contrast" value="<?php echo plugin_config_get('teamserver_url', '') ?>" />
                  </td>
                </tr>
                <tr <?php echo helper_alternate_class() ?>>
                  <td class="category" width="200"><?php echo plugin_lang_get('org_id'); ?></td>
                  <td><input name="org_id" size="50" value="<?php echo plugin_config_get('org_id', '') ?>" /></td>
                </tr>
                <tr <?php echo helper_alternate_class() ?>>
                  <td class="category" width="200"><?php echo plugin_lang_get('api_key'); ?></td>
                  <td><input name="api_key" size="50" value="<?php echo plugin_config_get('api_key', '') ?>" /></td>
                </tr>
                <tr <?php echo helper_alternate_class() ?>>
                  <td class="category" width="200"><?php echo plugin_lang_get('auth_header'); ?></td>
                  <td><input name="auth_header" size="100" value="<?php echo plugin_config_get('auth_header', '') ?>" /></td>
                </tr>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="col-md-12 col-xs-12">
    <?php echo plugin_lang_get('settings_guide'); ?>
  </div>
  <div class="col-md-12 col-xs-12">
    <div class="space-10"></div>
    <div class="form-container" >
      <div class="widget-box widget-color-blue2">
        <div class="widget-header widget-header-small">
          <h4 class="widget-title lighter"><?php echo plugin_lang_get('config_section_import') ?></h4>
        </div>
        <div class="widget-body">
          <div class="widget-main no-padding">
            <div class="table-responsive">
              <table class="table table-bordered table-condensed table-striped">
                <tr <?php echo helper_alternate_class() ?>> 
                  <td class="category" width="200"><?php echo plugin_lang_get('vul_issues'); ?></td>
                  <td>
                    <input type="checkbox" name="vul_issues" <?php if (plugin_config_get('vul_issues', ON) == ON) echo ' checked="checked"' ?> />
                  </td>
                </tr>
                <tr <?php echo helper_alternate_class() ?>> 
                  <td class="category" width="200"><?php echo plugin_lang_get('lib_issues'); ?></td>
                  <td>
                    <input type="checkbox" name="lib_issues" <?php if (plugin_config_get('lib_issues', ON) == ON) echo ' checked="checked"' ?> />
                  </td>
                </tr>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
  <div class="col-md-12 col-xs-12">
    <div class="space-10"></div>
    <div class="form-container" >
      <input type="submit" class="btn btn-primary btn-white btn-round" value="<?php echo plugin_lang_get('submit')?>" />
    </div>
  </div>
</form>
<?php
layout_page_end();

