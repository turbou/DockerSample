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
    params = context[:params]
    issue = context[:issue]
    cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.org_id')}).first
    cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.app_id')}).first
    cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')}).first
    org_id = cv_org.try(:value)
    app_id = cv_app.try(:value)
    vul_id = cv_vul.try(:value)
    if org_id.nil? || org_id.empty? || app_id.nil? || app_id.empty? || vul_id.nil? || vul_id.empty?
      return
    end
    status = ContrastUtil.get_contrast_status(issue.status.name)
    if status.nil?
      return
    end
    teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
    comment_suffix = Setting.plugin_contrastsecurity['comment_suffix']
    if comment_suffix.nil? || comment_suffix.empty?
      comment_suffix = "by Redmine."
    end
    # Get Status from TeamServer
    url = sprintf('%s/api/ng/%s/traces/%s/filter/%s?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
    res = callAPI(url, "GET", nil)
    vuln_json = JSON.parse(res.body)
    note = params['issue']['notes']
    if vuln_json['trace']['status'] != status
      # Put Status(and Comment) from TeamServer
      url = sprintf('%s/api/ng/%s/orgtraces/mark', teamserver_url, org_id)
      t_data_dict = {"traces" => [vul_id], "status" => status, "note" => comment_suffix}
      if (not note.nil?) && (not note.empty?)
        t_data_dict["note"] = note + " " + comment_suffix
      end
      callAPI(url, "PUT", t_data_dict.to_json)
    else
      if (not note.nil?) && (not note.empty?)
        url = sprintf('%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
        t_data = {"note" => note + " " + comment_suffix}.to_json
        callAPI(url, "POST", t_data)
      end
    end
  end

  def callAPI(url, method, data)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    if uri.scheme === "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    case method
    when "GET"
      req = Net::HTTP::Get.new(uri.request_uri)
    when "POST"
      req = Net::HTTP::Post.new(uri.request_uri)
      req.body = data
    when "PUT"
      req = Net::HTTP::Put.new(uri.request_uri)
      req.body = data
    else
      return
    end
    req["Authorization"] = Setting.plugin_contrastsecurity['auth_header']
    req["API-Key"] = Setting.plugin_contrastsecurity['api_key']
    req['Content-Type'] = req['Accept'] = 'application/json'
    res = http.request(req)
    return res
  end
end

