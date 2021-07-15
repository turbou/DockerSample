# MIT License
# Copyright (c) 2020 Contrast Security Japan G.K.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

module SettingsControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method_chain :plugin, :validate
    end
  end

  module InstanceMethods
    def plugin_with_validate
      @plugin = Redmine::Plugin.find(params[:id])
      if @plugin.name != "Contrast plugin"
        plugin = plugin_without_validate
        return plugin
      end

      if request.post?
        setting = params[:settings] ? params[:settings].permit!.to_h : {}
        Setting.send "plugin_#{@plugin.id}=", setting
        teamserver_url = setting['teamserver_url']
        org_id = setting['org_id']
        api_key = setting['api_key']
        username = setting['username']
        service_key = setting['service_key']
        proxy_host = setting['proxy_host']
        proxy_port = setting['proxy_port']
        proxy_user = setting['proxy_user']
        proxy_pass = setting['proxy_pass']
        if teamserver_url.empty? || org_id.empty? || api_key.empty? || username.empty? || service_key.empty?
          flash[:error] = l(:test_connect_fail)
          redirect_to plugin_settings_path(@plugin) and return
        end
        url = sprintf('%s/api/ng/%s/applications/', teamserver_url, org_id)
        res, msg = ContrastUtil.callAPI(
          url: url, api_key: api_key, username: username, service_key: service_key,
          proxy_host: proxy_host, proxy_port: proxy_port, proxy_user: proxy_user, proxy_pass: proxy_pass
        )
        if res.nil?
          flash[:error] = msg
          redirect_to plugin_settings_path(@plugin) and return
        else
          if res.code != "200"
            flash[:error] = l(:test_connect_fail)
            redirect_to plugin_settings_path(@plugin) and return
          end
        end
        # ステータスマッピングチェック
        statuses = []
        statuses << setting['sts_reported']
        statuses << setting['sts_suspicious']
        statuses << setting['sts_confirmed']
        statuses << setting['sts_notaproblem']
        statuses << setting['sts_remediated']
        statuses << setting['sts_fixed']
        statuses.each do |status|
          status_obj = IssueStatus.find_by_name(status)
          if status_obj.nil?
            flash[:error] = l(:status_settings_fail)
            redirect_to plugin_settings_path(@plugin) and return
          end
        end
        # 優先度マッピングチェック
        priorities = []
        priorities << setting['pri_critical']
        priorities << setting['pri_high']
        priorities << setting['pri_medium']
        priorities << setting['pri_low']
        priorities << setting['pri_note']
        priorities << setting['pri_cvelib']
        priorities.each do |priority|
          priority_obj = IssuePriority.find_by_name(priority)
          if priority_obj.nil?
            flash[:error] = l(:priority_settings_fail)
            redirect_to plugin_settings_path(@plugin) and return
          end
        end
      end
      plugin = plugin_without_validate
      return plugin
    end
  end
end

