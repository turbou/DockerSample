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
      cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.org_id')}).first
      cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.app_id')}).first
      cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')}).first
      cv_lib = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.lib_id')}).first
      cv_lib_lang = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.lib_lang')}).first
      org_id = cv_org.try(:value)
      app_id = cv_app.try(:value)
      vul_id = cv_vul.try(:value)
      lib_id = cv_lib.try(:value)
      lib_lang = cv_lib_lang.try(:value)
      type = nil
      if vul_id.present?
        if org_id.blank? || app_id.blank?
          show = show_without_update
          return show
        end 
        type = "VUL"
      elsif lib_id.present?
        if org_id.blank? || lib_lang.blank?
          show = show_without_update
          return show
        end 
        type = "LIB"
      else
        show = show_without_update
        return show
      end 
  
      if type == "VUL"
        teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
        url = sprintf('%s/api/ng/%s/traces/%s/trace/%s', teamserver_url, org_id, app_id, vul_id)
        res = callAPI(url)
        # puts res.code
        if res.code != "200"
          flash.now[:warning] = l(:vuln_does_not_exist)
          show = show_without_update
          return show
        end
        vuln_json = JSON.parse(res.body)
        last_time_seen = vuln_json['trace']['last_time_seen']
        severity = vuln_json['trace']['severity']
        priority = ContrastUtil.get_priority_by_severity(severity)
        unless priority.nil?
          @issue.priority = priority
        end 
        dt_format = Setting.plugin_contrastsecurity['vul_seen_dt_format']
        if dt_format.blank?
          dt_format = "%Y/%m/%d %H:%M"
        end
        @issue.custom_field_values.each do |cfv|
          if cfv.custom_field.name == l('contrast_custom_fields.last_seen') then
            cfv.value = Time.at(last_time_seen/1000.0).strftime(dt_format)
          elsif cfv.custom_field.name == l('contrast_custom_fields.severity') then
            cfv.value = severity
          end 
        end 
        @issue.save
        unless syncComment(org_id, app_id, vul_id, @issue)
          flash.now[:warning] = l(:sync_comment_failure)
        end
      else
        teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
        url = sprintf('%s/api/ng/%s/libraries/%s/%s?expand=vulns', teamserver_url, org_id, lib_lang, lib_id)
        res = callAPI(url)
        # puts res.code
        if res.code != "200"
          flash.now[:warning] = l(:lib_does_not_exist)
          show = show_without_update
          return show
        end
      end
      show = show_without_update
      return show
    end
  end

  def callAPI(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = false
    if uri.scheme === "https"
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    req = Net::HTTP::Get.new(uri.request_uri)
    req["Authorization"] = Setting.plugin_contrastsecurity['auth_header']
    req["API-Key"] = Setting.plugin_contrastsecurity['api_key']
    req['Content-Type'] = req['Accept'] = 'application/json'
    res = http.request(req)
    return res
  end

  def syncComment(org_id, app_id, vul_id, issue)
    teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
    url = sprintf('%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
    res = callAPI(url)
    if res.code != "200"
      return false
    end
    notes_json = JSON.parse(res.body)
    issue.journals.each do |c_journal|
      c_journal.destroy
    end
    hide_comment_id = Setting.plugin_contrastsecurity['hide_comment_id']
    exist_creator_pattern = /\(by .+\)/
    notes_json['notes'].reverse.each do |c_note|
      journal = Journal.new
      creator = "(by " + c_note['creator'] + ")"
      is_exist_creator = CGI.unescapeHTML(c_note['note']).match(exist_creator_pattern)
      if is_exist_creator
        creator = ""
      end
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
            status_change_reason_str = l(:notaproblem_reason) + " " + c_prop['value'] + "\n"
          end
        end
      end
      comment_id_str = "[" + c_note['id'] + "]"
      if hide_comment_id
        comment_id_str = "<input type=\"hidden\" name=\"comment_id\" value=\"" + c_note['id'] + "\" />"
      end
      note_str = CGI.unescapeHTML(status_change_reason_str + c_note['note']) + creator + "\n" + comment_id_str
      if old_status_str.present? && new_status_str.present?
        cmt_chg_msg = l(:status_changed_comment, :old => old_status_str, :new => new_status_str)
        note_str = "(" + cmt_chg_msg + ")\n" + CGI.unescapeHTML(status_change_reason_str + c_note['note']) + creator + "\n" + comment_id_str
      end
      journal.journalized = issue
      journal.user = User.current
      journal.notes = note_str
      journal.created_on = Time.at(c_note['creation']/1000.0)
      journal.save()
    end
    return true
  end
end

