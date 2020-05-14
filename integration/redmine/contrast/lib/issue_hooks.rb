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
    org_id = cv_org.value
    vul_id = cv_vul.value
    status = "Reported"
    case issue.status.name
      when "報告"
        status = "Reported"
      when "確認"
        status = "Confirmed"
      when "完了"
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

