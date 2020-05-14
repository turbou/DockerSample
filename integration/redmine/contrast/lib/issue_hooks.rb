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
  def controller_issues_edit_after_save(context)
    issue = context[:issue]
    cv_org = issue.custom_field_values.detect {|c| c.custom_field.name == 'contrast_org_id'}
    cv_vul = issue.custom_field_values.detect {|c| c.custom_field.name == 'contrast_vul_id'}
    if cv_vul.nil?
      return
    end
    sts_reported_array = [
      Setting.plugin_contrast['sts_reported_1'],
      Setting.plugin_contrast['sts_reported_2'],
      Setting.plugin_contrast['sts_reported_3']
    ]
    sts_suspicious_array = [
      Setting.plugin_contrast['sts_suspicious_1'],
      Setting.plugin_contrast['sts_suspicious_2'],
      Setting.plugin_contrast['sts_suspicious_3']
    ]
    sts_confirmed_array = [
      Setting.plugin_contrast['sts_confirmed_1'],
      Setting.plugin_contrast['sts_confirmed_2'],
      Setting.plugin_contrast['sts_confirmed_3']
    ]
    sts_notaproblem_array = [
      Setting.plugin_contrast['sts_notaproblem_1'],
      Setting.plugin_contrast['sts_notaproblem_2'],
      Setting.plugin_contrast['sts_notaproblem_3']
    ]
    sts_remediated_array = [
      Setting.plugin_contrast['sts_remediated_1'],
      Setting.plugin_contrast['sts_remediated_2'],
      Setting.plugin_contrast['sts_remediated_3']
    ]
    sts_fixed_array = [
      Setting.plugin_contrast['sts_fixed_1'],
      Setting.plugin_contrast['sts_fixed_2'],
      Setting.plugin_contrast['sts_fixed_3']
    ]
    org_id = cv_org.value
    vul_id = cv_vul.value
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
    teamserver_url = Setting.plugin_contrast['teamserver_url']
    url = sprintf('%s/api/ng/%s/orgtraces/mark', teamserver_url, org_id)
    t_data = {"traces" => [vul_id], "status" => status, "note" => "by MantisBT."}.to_json
    puts t_data
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Put.new(uri.request_uri)
    req["Authorization"] = Setting.plugin_contrast['auth_header']
    req["API-Key"] = Setting.plugin_contrast['api_key']
    req['Content-Type'] = req['Accept'] = 'application/json'
    req.body = t_data
    res = http.request(req)
  end
end

