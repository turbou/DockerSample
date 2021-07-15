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

module ContrastUtil
  include Redmine::I18n
  def self.get_priority_by_severity(severity)
    case severity
    when "Critical"
      priority_str = Setting.plugin_contrastsecurity['pri_critical']
    when "High"
      priority_str = Setting.plugin_contrastsecurity['pri_high']
    when "Medium"
      priority_str = Setting.plugin_contrastsecurity['pri_medium']
    when "Low"
      priority_str = Setting.plugin_contrastsecurity['pri_low']
    when "Note"
      priority_str = Setting.plugin_contrastsecurity['pri_note']
    end 
    priority = IssuePriority.find_by_name(priority_str)
    return priority
  end

  def self.get_redmine_status(contrast_status)
    case contrast_status
    when "Reported", "報告済"
      rm_status = Setting.plugin_contrastsecurity['sts_reported']
    when "Suspicious", "疑わしい"
      rm_status = Setting.plugin_contrastsecurity['sts_suspicious']
    when "Confirmed", "確認済"
      rm_status = Setting.plugin_contrastsecurity['sts_confirmed']
    when "NotAProblem", "Not a Problem", "問題無し"
      rm_status = Setting.plugin_contrastsecurity['sts_notaproblem']
    when "Remediated", "修復済"
      rm_status = Setting.plugin_contrastsecurity['sts_remediated']
    when "Fixed", "修正完了"
      rm_status = Setting.plugin_contrastsecurity['sts_fixed']
    end 
    status = IssueStatus.find_by_name(rm_status)
    return status
  end

  def self.get_contrast_status(redmine_status)
    sts_reported_array = [Setting.plugin_contrastsecurity['sts_reported']]
    sts_suspicious_array = [Setting.plugin_contrastsecurity['sts_suspicious']]
    sts_confirmed_array = [Setting.plugin_contrastsecurity['sts_confirmed']]
    sts_notaproblem_array = [Setting.plugin_contrastsecurity['sts_notaproblem']]
    sts_remediated_array = [Setting.plugin_contrastsecurity['sts_remediated']]
    sts_fixed_array = [Setting.plugin_contrastsecurity['sts_fixed']]
    status = nil
    if sts_reported_array.include?(redmine_status)
      status = "Reported"
    elsif sts_suspicious_array.include?(redmine_status)
      status = "Suspicious"
    elsif sts_confirmed_array.include?(redmine_status)
      status = "Confirmed"
    elsif sts_notaproblem_array.include?(redmine_status)
      status = "NotAProblem"
    elsif sts_remediated_array.include?(redmine_status)
      status = "Remediated"
    elsif sts_fixed_array.include?(redmine_status)
      status = "Fixed"
    end
    return status
  end

  def callAPI(url: , method: "GET", data: nil, api_key: nil, username: nil, service_key: nil, proxy_host: nil, proxy_port: nil, proxy_user: nil, proxy_pass: nil)
    uri = URI.parse(url)
    http = nil
    proxy_host ||= Setting.plugin_contrastsecurity['proxy_host']
    proxy_port ||= Setting.plugin_contrastsecurity['proxy_port']
    proxy_user ||= Setting.plugin_contrastsecurity['proxy_user']
    proxy_pass ||= Setting.plugin_contrastsecurity['proxy_pass']
    proxy_uri = ""
    if proxy_host.present? && proxy_port.present?
      proxy_uri = URI.parse(sprintf('http://%s:%d', proxy_host, proxy_port))
      if proxy_user.present? && proxy_pass.present?
        http = Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port, proxy_user, proxy_pass)
      else
        http = Net::HTTP.new(uri.host, uri.port, proxy_uri.host, proxy_uri.port)
      end
    else
      http = Net::HTTP.new(uri.host, uri.port)
    end
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
    when "DELETE"
      req = Net::HTTP::Delete.new(uri.request_uri)
    else
      return
    end
    # TeamServer接続設定のみparamから渡されたものを使う。なければ設定から取得
    api_key ||= Setting.plugin_contrastsecurity['api_key']
    username ||= Setting.plugin_contrastsecurity['username']
    service_key ||= Setting.plugin_contrastsecurity['service_key']

    auth_header = Base64.strict_encode64(username + ":" + service_key)
    req["Authorization"] = auth_header
    req["API-Key"] = api_key
    req['Content-Type'] = req['Accept'] = 'application/json'
    begin
      res = http.request(req)
      return res, nil
    rescue => e
      puts [uri.to_s, e.class, e].join(" : ")
      return nil, e.to_s 
    end
  end
  module_function :callAPI

  def syncComment(org_id, app_id, vul_id, issue)
    teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
    url = sprintf('%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
    res, msg = callAPI(url: url)
    if res.present? && res.code != "200"
      return false
    end
    notes_json = JSON.parse(res.body)
    issue.journals.each do |c_journal|
      if not c_journal.private_notes
        c_journal.destroy
      end
    end
    notes_json['notes'].reverse.each do |c_note|
      old_status_str = ""
      new_status_str = ""
      status_change_reason_str = ""
      if c_note.has_key?("properties")
        c_note['properties'].each do |c_prop|
          if c_prop['name'] == "status.change.previous.status"
            status_obj = ContrastUtil.get_redmine_status(c_prop['value'])
            unless status_obj.nil?
              old_status_str = status_obj.name
            end
          elsif c_prop['name'] == "status.change.status"
            status_obj = ContrastUtil.get_redmine_status(c_prop['value'])
            unless status_obj.nil?
              new_status_str = status_obj.name
            end
          elsif c_prop['name'] == "status.change.substatus" && c_prop['value'].present?
            status_change_reason_str = l(:notaproblem_reason, :reason => c_prop['value']) + "\n"
          end
        end
      end
      note_str = CGI.unescapeHTML(status_change_reason_str + c_note['note'])
      if old_status_str.present? && new_status_str.present?
        cmt_chg_msg = l(:status_changed_comment, :old => old_status_str, :new => new_status_str)
        note_str = "(" + cmt_chg_msg + ")\n" + CGI.unescapeHTML(status_change_reason_str + c_note['note'])
      end
      journal = Journal.new
      journal.journalized = issue
      journal.user = User.current
      journal.notes = note_str
      journal.created_on = Time.at(c_note['last_modification']/1000.0)
      journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_note_id", value: c_note['id'])
      journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_last_updater_uid", value: c_note['last_updater_uid'])
      journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_last_updater", value: c_note['last_updater'])
      journal.save()
    end
    return true
  end
  module_function :syncComment
end

