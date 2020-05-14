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

