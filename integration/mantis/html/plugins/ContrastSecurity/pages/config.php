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
  <div class="form-container" >
    <form name="plugins_releases" method="post" action="<?php echo plugin_page('config_update') ?>">
      <?php echo form_security_field('plugin_ContrastSecurity_config_update') ?>
      <div class="widget-box widget-color-blue2">
        <div class="widget-header widget-header-small">
          <h4 class="widget-title lighter"><?php echo plugin_lang_get('config_section_general') ?></h4>
        </div>
        <div class="widget-body">
          <div class="widget-main no-padding">
            <div class="table-responsive">
              <table class="table table-bordered table-condensed table-striped">
                <tr <?php echo helper_alternate_class() ?>>
                  <td class="category" width="150"><?php echo plugin_lang_get('teamserver_url'); ?></td>
                  <td>
                    <input name="teamserver_url" size="75" value="<?php echo plugin_config_get('teamserver_url', '') ?>" />
                  </td>
                </tr>
                <tr <?php echo helper_alternate_class() ?>>
                  <td class="category" width="150"><?php echo plugin_lang_get('api_key'); ?></td>
                  <td><input name="api_key" size="30" value="<?php echo plugin_config_get('api_key', '') ?>" /></td>
                </tr>
                <tr <?php echo helper_alternate_class() ?>>
                  <td class="category" width="150"><?php echo plugin_lang_get('auth_header'); ?></td>
                  <td><input name="auth_header" size="100" value="<?php echo plugin_config_get('auth_header', '') ?>" /></td>
                </tr>
              </table>
            </div>
          </div>
          <div class="widget-toolbox padding-8 clearfix">
            <input type="submit" class="btn btn-primary btn-white btn-round" value="<?php echo lang_get('change_configuration')?>" />
          </div>
        </div>
      </div>
      <?php echo plugin_lang_get('settings_guide') ?>
    </form>
  </div>
</div>

<?php
layout_page_end();

