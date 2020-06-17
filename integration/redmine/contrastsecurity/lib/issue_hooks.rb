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
class IssueHook < Redmine::Hook::Listener
  def view_issues_show_description_bottom(context)
    issue = context[:issue]
    cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】組織ID'}).first
    cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】アプリID'}).first
    cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】脆弱性ID'}).first
    org_id = cv_org.try(:value)
    app_id = cv_app.try(:value)
    vul_id = cv_vul.try(:value)
    if org_id.nil? || app_id.nil? || vul_id.nil?
      return
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
    vuln_json = JSON.parse(res.body)
    last_time_seen = vuln_json['trace']['last_time_seen']
    issue.custom_field_values.each do |cfv|
      if cfv.custom_field.name == '【Contrast】最後の検出' then
        cfv.value = Time.at(last_time_seen/1000.0).strftime('%Y-%m-%dT%H:%M:%S.%LZ')
      end
    end
    issue.save
  end

  def controller_issues_edit_after_save(context)
    issue = context[:issue]
    #cv_org = issue.custom_field_values.detect {|c| c.custom_field.name == '【Contrast】組織ID'}
    #cv_vul = issue.custom_field_values.detect {|c| c.custom_field.name == '【Contrast】脆弱性ID'}
    cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】組織ID'}).first
    cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】脆弱性ID'}).first
    org_id = cv_org.try(:value)
    vul_id = cv_vul.try(:value)
    if org_id.nil? || vul_id.nil?
      return
    end

    sts_reported_array = [Setting.plugin_contrastsecurity['sts_reported']]
    sts_suspicious_array = [Setting.plugin_contrastsecurity['sts_suspicious']]
    sts_confirmed_array = [Setting.plugin_contrastsecurity['sts_confirmed']]
    sts_notaproblem_array = [Setting.plugin_contrastsecurity['sts_notaproblem']]
    sts_remediated_array = [Setting.plugin_contrastsecurity['sts_remediated']]
    sts_fixed_array = [Setting.plugin_contrastsecurity['sts_fixed']]
    if sts_reported_array.include?(issue.status.name) 
      status = "Reported"
    elsif sts_suspicious_array.include?(issue.status.name) 
      status = "Suspicious"
    elsif sts_confirmed_array.include?(issue.status.name) 
      status = "Confirmed"
    elsif sts_notaproblem_array.include?(issue.status.name) 
      status = "NotAProblem"
    elsif sts_remediated_array.include?(issue.status.name) 
      status = "Remediated"
    elsif sts_fixed_array.include?(issue.status.name) 
      status = "Fixed"
    else
      return
    end
    teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
    url = sprintf('%s/api/ng/%s/orgtraces/mark', teamserver_url, org_id)
    t_data = {"traces" => [vul_id], "status" => status, "note" => "by Redmine."}.to_json
    #puts t_data
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Put.new(uri.request_uri)
    req["Authorization"] = Setting.plugin_contrastsecurity['auth_header']
    req["API-Key"] = Setting.plugin_contrastsecurity['api_key']
    req['Content-Type'] = req['Accept'] = 'application/json'
    req.body = t_data
    res = http.request(req)
  end
end

