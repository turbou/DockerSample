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
  def controller_issues_bulk_edit_before_save(context)
    issue = context[:issue]
    cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.org_id')}).first
    cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.app_id')}).first
    cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')}).first
    org_id = cv_org.try(:value)
    app_id = cv_app.try(:value)
    vul_id = cv_vul.try(:value)
    if org_id.blank? || app_id.blank? || vul_id.blank?
      return
    end
    status = ContrastUtil.get_contrast_status(issue.status.name)
    if status.nil?
      return
    end
    teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
    # Get Status from TeamServer
    url = sprintf('%s/api/ng/%s/traces/%s/filter/%s?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
    res, msg = ContrastUtil.callAPI(url: url)
    vuln_json = JSON.parse(res.body)
    sts_chg_ptn = "\\(" + l(:text_journal_changed, :label => ".+", :old => ".+", :new => ".+") + "\\)\\R"
    sts_chg_pattern = /#{sts_chg_ptn}/
    reason_ptn = l(:notaproblem_reason, :reason => ".+") + "\\R"
    reason_pattern = /#{reason_ptn}/
    if vuln_json['trace']['status'] != status
      # Put Status(and Comment) from TeamServer
      url = sprintf('%s/api/ng/%s/orgtraces/mark', teamserver_url, org_id)
      t_data_dict = {"traces" => [vul_id], "status" => status}
      t_data_dict["note"] = "status changed (by " + User.current.name + ")"
      ContrastUtil.callAPI(url: url, method: "PUT", data: t_data_dict.to_json)
    end
  end

  def controller_journals_edit_post(context)
    journal = context[:journal]
    private_note = journal.private_notes
    issue = journal.journalized
    cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.org_id')}).first
    cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.app_id')}).first
    cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')}).first
    org_id = cv_org.try(:value)
    app_id = cv_app.try(:value)
    vul_id = cv_vul.try(:value)
    if org_id.blank? || app_id.blank? || vul_id.blank?
      return
    end
    note_id = nil
    journal.details.each do |detail|
      if detail.prop_key == "contrast_note_id"
        note_id = detail.value
      end
    end
    teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
    url = sprintf('%s/api/ng/%s/applications/%s/traces/%s/notes/%s?expand=skip_links', teamserver_url, org_id, app_id, vul_id, note_id)
    if note_id.present?
      if private_note
        # プライベート注記に変更された場合
        details = journal.details.to_a.delete_if{|detail| detail.prop_key == "contrast_note_id"}
        journal.details = details
        journal.save
        ContrastUtil.callAPI(url: url, method: "DELETE")
      end
    end

    note = journal.notes
    sts_chg_ptn = "\\(" + l(:text_journal_changed, :label => ".+", :old => ".+", :new => ".+") + "\\)\\R"
    sts_chg_pattern = /#{sts_chg_ptn}/
    reason_ptn = l(:notaproblem_reason, :reason => ".+") + "\\R"
    reason_pattern = /#{reason_ptn}/
    note = note.sub(/#{sts_chg_ptn}/, "")
    note = note.sub(/#{reason_ptn}/, "")
    t_data = {"note" => note}.to_json
    if note_id.blank? && !private_note # note idがなく、でもプライベート注記じゃない（またプライベート注記じゃなくなった）場合
      res, msg = ContrastUtil.callAPI(url: url, method: "POST", data: t_data)
      # note idを取得してredmine側のコメントに反映する。
      note_json = JSON.parse(res.body)
      if note_json['success']
        journal.notes = CGI.unescapeHTML(note_json['note']['note'])
        journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_note_id", value: note_json['note']['id'])
        journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_last_updater_uid", value: note_json['note']['last_updater_uid'])
        journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_last_updater", value: note_json['note']['last_updater'])
        journal.save()
      end
    else
      ContrastUtil.callAPI(url: url, method: "PUT", data: t_data)
    end
  end

  def controller_issues_edit_after_save(context)
    params = context[:params]
    issue = context[:issue]
    journal = context[:journal]
    cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.org_id')}).first
    cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.app_id')}).first
    cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')}).first
    org_id = cv_org.try(:value)
    app_id = cv_app.try(:value)
    vul_id = cv_vul.try(:value)
    if org_id.blank? || app_id.blank? || vul_id.blank?
      return
    end
    status = ContrastUtil.get_contrast_status(issue.status.name)
    if status.nil?
      return
    end
    teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
    # Get Status from TeamServer
    url = sprintf('%s/api/ng/%s/traces/%s/filter/%s?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
    res, msg = ContrastUtil.callAPI(url: url)
    vuln_json = JSON.parse(res.body)
    note = params['issue']['notes']
    private_note = params['issue']['private_notes']
    sts_chg_ptn = "\\(" + l(:text_journal_changed, :label => ".+", :old => ".+", :new => ".+") + "\\)\\R"
    sts_chg_pattern = /#{sts_chg_ptn}/
    reason_ptn = l(:notaproblem_reason, :reason => ".+") + "\\R"
    reason_pattern = /#{reason_ptn}/
    note = note.sub(/#{sts_chg_ptn}/, "")
    note = note.sub(/#{reason_ptn}/, "")
    if vuln_json['trace']['status'] != status
      # Put Status(and Comment) from TeamServer
      url = sprintf('%s/api/ng/%s/orgtraces/mark', teamserver_url, org_id)
      t_data_dict = {"traces" => [vul_id], "status" => status}
      if note.present? && private_note == "0"
        t_data_dict["note"] = note + " (by " + issue.last_updated_by.name + ")"
      else
        t_data_dict["note"] = "status changed (by " + issue.last_updated_by.name + ")"
      end
      ContrastUtil.callAPI(url: url, method: "PUT", data: t_data_dict.to_json)
    else
      if note.present? && private_note == "0"
        url = sprintf('%s/api/ng/%s/applications/%s/traces/%s/notes?expand=skip_links', teamserver_url, org_id, app_id, vul_id)
        t_data = {"note" => note + " (by " + issue.last_updated_by.name + ")"}.to_json
        res, msg = ContrastUtil.callAPI(url: url, method: "POST", data: t_data)
        # note idを取得してredmine側のコメントに反映する。
        note_json = JSON.parse(res.body)
        if note_json['success']
          journal.notes = CGI.unescapeHTML(note_json['note']['note'])
          journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_note_id", value: note_json['note']['id'])
          journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_last_updater_uid", value: note_json['note']['last_updater_uid'])
          journal.details << JournalDetail.new(property: "cf", prop_key: "contrast_last_updater", value: note_json['note']['last_updater'])
          journal.save()
        end
      end
    end
  end
end

