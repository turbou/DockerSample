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
        teamserver_url = setting['teamserver_url']
        org_id = setting['org_id']
        api_key = setting['api_key']
        auth_header = setting['auth_header']
        puts auth_header
        url = sprintf('%s/api/ng/%s/applications/', teamserver_url, org_id)
        puts url
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = false
        if uri.scheme === "https"
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        req = Net::HTTP::Get.new(uri.request_uri)
        req["Authorization"] = auth_header
        req["API-Key"] = api_key
        req['Content-Type'] = req['Accept'] = 'application/json'
        res = http.request(req)
        puts res.code
        puts res.body
        #apps_json = JSON.parse(res.body)
        #puts apps_json
        if res.code != "200"
          flash.now[:notice] = l(:test_connect_fail)
          #redirect_to plugin_settings_path(@plugin) and return
        else
          plugin = plugin_without_validate
          return plugin
        end
        plugin = plugin_without_validate
        return plugin
      end
      plugin = plugin_without_validate
      return plugin
    end
  end
end

