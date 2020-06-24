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
module IssuesControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method_chain :show, :update
    end
  end

  module InstanceMethods
    def show_with_update
      cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】組織ID'}).first
      cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】アプリID'}).first
      cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】脆弱性ID'}).first
      org_id = cv_org.try(:value)
      app_id = cv_app.try(:value)
      vul_id = cv_vul.try(:value)
      if org_id.nil? || org_id.empty? || app_id.nil? || app_id.empty? || vul_id.nil? || vul_id.empty?
        show = show_without_update
        return show
      end 
  
      teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
      url = sprintf('%s/api/ng/%s/traces/%s/trace/%s', teamserver_url, org_id, app_id, vul_id)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.request_uri)
      req["Authorization"] = Setting.plugin_contrastsecurity['auth_header']
      req["API-Key"] = Setting.plugin_contrastsecurity['api_key']
      req['Content-Type'] = req['Accept'] = 'application/json'
      res = http.request(req)
      if res.code != 200
        flash.now[:warning] = l(:vuln_does_not_exist)
        show = show_without_update
        return show
      end
      vuln_json = JSON.parse(res.body)
      last_time_seen = vuln_json['trace']['last_time_seen']
      severity = vuln_json['trace']['severity']
      priority = ContrastUtil.get_priority_by_severity(severity)
      if not priority.nil?
        @issue.priority = priority
      end 
      @issue.custom_field_values.each do |cfv|
        if cfv.custom_field.name == '【Contrast】最後の検出' then
          cfv.value = Time.at(last_time_seen/1000.0).strftime('%Y-%m-%dT%H:%M:%S.%LZ')
        elsif cfv.custom_field.name == '【Contrast】深刻度' then
          cfv.value = severity
        end 
      end 
      @issue.save
      show = show_without_update
      return show
    end
  end
end

