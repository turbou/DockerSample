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

class ContrastController < ApplicationController
  before_action :require_login
  skip_before_filter :verify_authenticity_token
  accept_api_auth :vote

  CUSTOM_FIELDS = [
    l('contrast_custom_fields.rule'), l('contrast_custom_fields.category'), l('contrast_custom_fields.server'), l('contrast_custom_fields.module'),
    l('contrast_custom_fields.confidence'), l('contrast_custom_fields.severity'), l('contrast_custom_fields.last_seen'), l('contrast_custom_fields.first_seen'),
    l('contrast_custom_fields.lib_lang'), l('contrast_custom_fields.lib_id'), l('contrast_custom_fields.vul_id'), l('contrast_custom_fields.app_id'), l('contrast_custom_fields.org_id'),
  ].freeze

  def vote
    #logger.info(request.body.read)
    t_issue = JSON.parse(request.body.read)
    #logger.info(t_issue['description'])
    event_type = t_issue['event_type']
    project_identifier = t_issue['project']
    tracker_str = t_issue['tracker']
    project = Project.find_by_identifier(project_identifier)
    tracker = Tracker.find_by_name(tracker_str)
    if project.nil? || tracker.nil?
      return head :not_found
    end
    if not tracker.projects.include? project
      tracker.projects << project
      tracker.save
    end
    add_custom_fields = []
    if 'NEW_VULNERABILITY' == event_type
      logger.info(l(:event_new_vulnerability))
      if not Setting.plugin_contrastsecurity['vul_issues']
        return render plain: 'Vul Skip'
      end
      app_name = t_issue['application_name']
      org_id = t_issue['organization_id']
      app_id = t_issue['application_id']
      vul_id = t_issue['vulnerability_id']
      lib_id = ''
      self_url = ""
      vulurl_pattern = /.+\((.+#{vul_id})\)/
      is_vulurl = t_issue['description'].match(vulurl_pattern)
      if is_vulurl
        self_url = is_vulurl[1]
      end
      # /Contrast/api/ng/[ORG_ID]/traces/[APP_ID]/trace/[VUL_ID]
      teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
      url = sprintf('%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application', teamserver_url, org_id, app_id, vul_id)
      #logger.info(url)
      res = callAPI(url)
      vuln_json = JSON.parse(res.body)
      #logger.info(vuln_json)
      summary = '[' + app_name + '] ' + vuln_json['trace']['title']
      first_time_seen = vuln_json['trace']['first_time_seen']
      last_time_seen = vuln_json['trace']['last_time_seen']
      category = vuln_json['trace']['category']
      confidence = vuln_json['trace']['confidence']
      rule_title = vuln_json['trace']['rule_title']
      severity = vuln_json['trace']['severity']
      priority = ContrastUtil.get_priority_by_severity(severity)
      status = vuln_json['trace']['status']
      status_obj = ContrastUtil.get_redmine_status(status)
      #logger.info(priority)
      if priority.nil?
        logger.error(l(:problem_with_priority))
        return head :not_found
      end
      module_str = app_name + " (" + vuln_json['trace']['application']['context_path'] + ") - " + vuln_json['trace']['application']['language']
      server_list = Array.new
      vuln_json['trace']['servers'].each do |c_server|
        server_list.push(c_server['name'])
      end
      dt_format = Setting.plugin_contrastsecurity['vul_seen_dt_format']
      if dt_format.blank?
        dt_format = "%Y/%m/%d %H:%M"
      end
      add_custom_fields << {'id_str': l('contrast_custom_fields.first_seen'), 'value': Time.at(first_time_seen/1000.0).strftime(dt_format)}
      add_custom_fields << {'id_str': l('contrast_custom_fields.last_seen'), 'value': Time.at(last_time_seen/1000.0).strftime(dt_format)}
      add_custom_fields << {'id_str': l('contrast_custom_fields.severity'), 'value': severity}
      add_custom_fields << {'id_str': l('contrast_custom_fields.confidence'), 'value': confidence}
      add_custom_fields << {'id_str': l('contrast_custom_fields.module'), 'value': module_str}
      add_custom_fields << {'id_str': l('contrast_custom_fields.server'), 'value': server_list.join(", ")}
      add_custom_fields << {'id_str': l('contrast_custom_fields.category'), 'value': category}
      add_custom_fields << {'id_str': l('contrast_custom_fields.rule'), 'value': rule_title}
      #logger.info(add_custom_fields)
      story_url = ''
      howtofix_url = ''
      vuln_json['trace']['links'].each do |c_link|
        if c_link['rel'] == 'story'
          story_url = c_link['href']
          if story_url.include?("{traceUuid}")
            story_url = story_url.sub(/{traceUuid}/, vul_id)
          end
        end
        if c_link['rel'] == 'recommendation'
          howtofix_url = c_link['href']
          if howtofix_url.include?("{traceUuid}")
            howtofix_url = howtofix_url.sub(/{traceUuid}/, vul_id)
          end
        end
      end
      #logger.info(summary)
      #logger.info(story_url)
      #logger.info(howtofix_url)
      #logger.info(self_url)
      # Story
      story = ""
      if story_url.present?
        get_story_res = callAPI(story_url)
        story_json = JSON.parse(get_story_res.body)
        story = story_json['story']['risk']['formattedText']
      end
      # How to fix
      howtofix = ""
      if howtofix_url.present?
        get_howtofix_res = callAPI(howtofix_url)
        howtofix_json = JSON.parse(get_howtofix_res.body)
        howtofix = howtofix_json['recommendation']['formattedText']
      end
      # description
      deco_mae = ""
      deco_ato = ""
      if Setting.text_formatting == "textile"
        deco_mae = "h2. "
        deco_ato = "\n"
      elsif Setting.text_formatting == "markdown"
        deco_mae = "## "
      end
      description = ""
      description << deco_mae + l(:report_vul_overview) + deco_ato + "\n"
      description << convertMustache(story) + "\n\n"
      description << deco_mae + l(:report_vul_howtofix) + deco_ato + "\n"
      description << convertMustache(howtofix) + "\n\n"
      description << deco_mae + l(:report_vul_url) + deco_ato + "\n"
      description << self_url
    elsif 'VULNERABILITY_CHANGESTATUS_OPEN' == event_type || 'VULNERABILITY_CHANGESTATUS_CLOSED' == event_type
      logger.info(l(:event_vulnerability_changestatus))
      project = t_issue['project']
      status = t_issue['status']
      #logger.info(status)
      vul_sts_chg_pattern = /index.html#\/(.+)\/applications\/(.+)\/vulns\/(.+)\) found in/
      is_vul_sts_chg = t_issue['description'].match(vul_sts_chg_pattern)
      if is_vul_sts_chg
        #org_id = is_vul_sts_chg[1]
        #app_id = is_vul_sts_chg[2]
        vul_id = is_vul_sts_chg[3]
        if vul_id.blank?
          logger.error(l(:problem_with_customfield))
          return head :ok
        end
        cvs = CustomValue.where(customized_type: 'Issue', value: vul_id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')})
        cvs.each do |cv|
          issue = cv.customized
          if project != issue.project.identifier
            next
          end
          status_obj = ContrastUtil.get_redmine_status(status)
          if status_obj.nil?
            logger.error(l(:problem_with_status))
            return head :ok
          end
          old_status_obj = issue.status
          issue.status = status_obj
          if issue.save
            logger.info(l(:issue_status_change_success))
            return head :ok
          else
            logger.error(l(:issue_status_change_failure))
            return head :internal_server_error
          end
        end
      end
      return head :ok
    elsif 'NEW_VULNERABLE_LIBRARY' == event_type
      logger.info(l(:event_new_vulnerable_library))
      if not Setting.plugin_contrastsecurity['lib_issues']
        return render plain: 'Lib Skip'
      end
      org_id = t_issue['organization_id']
      app_id = t_issue['application_id']
      lib_pattern = /index.html#\/#{org_id}\/libraries\/(.+)\/([a-z0-9]+)\)/
      is_lib = t_issue['description'].match(lib_pattern)
      vul_id = ''
      lib_lang = is_lib[1]
      lib_id = is_lib[2]
      teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
      url = sprintf('%s/api/ng/%s/libraries/%s/%s?expand=vulns', teamserver_url, org_id, lib_lang, lib_id)
      res = callAPI(url)
      lib_json = JSON.parse(res.body)
      lib_name = lib_json['library']['file_name']
      file_version = lib_json['library']['file_version']
      latest_version = lib_json['library']['latest_version']
      classes_used = lib_json['library']['classes_used']
      class_count = lib_json['library']['class_count']
      cve_list = Array.new
      lib_json['library']['vulns'].each do |c_link|
        cve_list.push(c_link['name'])
      end
      priority_str = Setting.plugin_contrastsecurity['pri_cvelib']
      priority = IssuePriority.find_by_name(priority_str)
      #logger.info(priority)
      if priority.nil?
        logger.error(l(:problem_with_priority))
        return head :not_found
      end
      liburl_pattern = /.+ was found in .+\((.+)\),.+/
      is_liburl = t_issue['description'].match(liburl_pattern)
      self_url = ''
      if is_liburl
        self_url = is_liburl[1]
      end
      summary = lib_name
      # description
      deco_mae = ""
      deco_ato = ""
      if Setting.text_formatting == "textile"
        deco_mae = "*"
        deco_ato = "*"
      elsif Setting.text_formatting == "markdown"
        deco_mae = "**"
        deco_ato = "**"
      end
      description = ""
      description << deco_mae + l(:report_lib_curver) + deco_ato + "\n"
      description << file_version + "\n\n"
      description << deco_mae + l(:report_lib_newver) + deco_ato + "\n"
      description << latest_version + "\n\n"
      description << deco_mae + l(:report_lib_class) + deco_ato + "\n"
      description << classes_used.to_s + "/" + class_count.to_s + "\n\n"
      description << deco_mae + l(:report_lib_cves) + deco_ato + "\n"
      description << cve_list.join("\n") + "\n\n"
      description << deco_mae + l(:report_lib_url) + deco_ato + "\n"
      description << self_url
    elsif 'NEW_VULNERABILITY_COMMENT_FROM_SCRIPT' == event_type
      logger.info(l(:event_new_vulnerability_comment))
      vul_id_pattern = /.+ commented on a .+[^(]+ \(.+index.html#\/(.+)\/applications\/(.+)\/vulns\/([^)]+)\)/
      project = t_issue['project']
      is_vul_id = t_issue['description'].match(vul_id_pattern)
      if is_vul_id
        org_id = is_vul_id[1]
        app_id = is_vul_id[2]
        vul_id = is_vul_id[3]
        cvs = CustomValue.where(customized_type: 'Issue', value: vul_id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')})
        cvs.each do |cv|
          issue = cv.customized
          if project == issue.project.identifier
            syncComment(org_id, app_id, vul_id, issue)
          end
        end
      end
      return head :ok
    else
      vulnerability_tags = t_issue['vulnerability_tags']
      if 'VulnerabilityTestTag' == vulnerability_tags
        #logger.info(t_issue['description'])
        return render plain: 'Test URL Success'
      end
      return head :ok
    end
    custom_field_hash = {}
    CUSTOM_FIELDS.each do |custom_field_name|
      custom_field = IssueCustomField.find_by_name(custom_field_name)
      if custom_field.nil?
        custom_field = IssueCustomField.new(name: custom_field_name)
        custom_field.position = 1
        custom_field.visible = true
        custom_field.is_required = false
        custom_field.is_filter = false
        custom_field.searchable = false
        custom_field.field_format = 'string'
        custom_field.projects << project
        custom_field.trackers << tracker
        custom_field.save
      else
        if not custom_field.projects.include? project
          custom_field.projects << project
          custom_field.save
        end
        if not custom_field.trackers.include? tracker
          custom_field.trackers << tracker
          custom_field.save
        end
      end
      custom_field_hash[custom_field_name] = custom_field.id
    end
    custom_fields = [
      {'id': custom_field_hash[l('contrast_custom_fields.org_id')], 'value': org_id},
      {'id': custom_field_hash[l('contrast_custom_fields.app_id')], 'value': app_id},
      {'id': custom_field_hash[l('contrast_custom_fields.vul_id')], 'value': vul_id},
      {'id': custom_field_hash[l('contrast_custom_fields.lib_id')], 'value': lib_id},
      {'id': custom_field_hash[l('contrast_custom_fields.lib_lang')], 'value': lib_lang},
    ]
    add_custom_fields.each do |add_custom_field|
      custom_fields << {'id': custom_field_hash[add_custom_field[:id_str]], 'value': add_custom_field[:value]}
    end
    #logger.info(custom_fields)
    issue = Issue.new(
      project: project,
      subject: summary,
      tracker: tracker,
      priority: priority,
      description: description,
      custom_fields: custom_fields,
      author: User.current
    )
    unless status_obj.nil?
      issue.status = status_obj
    end
    if issue.save
      logger.info(l(:issue_create_success))
      return head :ok
    else
      logger.error(l(:issue_create_failure))
      return head :internal_server_error
    end
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
            status_change_reason_str = l(:notaproblem_reason, :reason => c_prop['value']) + "\n"
          end
        end
      end
      note_str = CGI.unescapeHTML(status_change_reason_str + c_note['note']) + creator
      if old_status_str.present? && new_status_str.present?
        cmt_chg_msg = l(:status_changed_comment, :old => old_status_str, :new => new_status_str)
        note_str = "(" + cmt_chg_msg + ")\n" + CGI.unescapeHTML(status_change_reason_str + c_note['note']) + creator
      end
      journal.journalized = issue
      journal.user = User.current
      journal.notes = note_str
      journal.created_on = Time.at(c_note['creation']/1000.0)
      journal.details << JournalDetail.new(property: "relation", prop_key: "note_id", value: c_note['id'])
      journal.save()
    end
    return true
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

  def convertMustache(str)
    if Setting.text_formatting == "textile"
      # Link
      new_str = str.gsub(/{{#link}}(.+?)\$\$LINK_DELIM\$\$(.+?){{\/link}}/, '"\2":\1 ')
      # CodeBlock
      new_str = new_str.gsub(/{{#[A-Za-z]+Block}}/, '<pre>').gsub(/{{\/[A-Za-z]+Block}}/, '</pre>')
      # Header
      new_str = new_str.gsub(/{{#header}}/, 'h3. ').gsub(/{{\/header}}/, "\n")
      # List
      new_str = new_str.gsub(/{{#listElement}}/, '* ').gsub(/{{\/listElement}}/, '')
    elsif Setting.text_formatting == "markdown"
      # Link
      new_str = str.gsub(/{{#link}}(.+?)\$\$LINK_DELIM\$\$(.+?){{\/link}}/, '[\2](\1)')
      # CodeBlock
      new_str = new_str.gsub(/{{#[A-Za-z]+Block}}/, "~~~\n").gsub(/{{\/[A-Za-z]+Block}}/, "\n~~~")
      # Header
      new_str = new_str.gsub(/{{#header}}/, '### ').gsub(/{{\/header}}/, '')
      # List
      new_str = new_str.gsub(/{{#listElement}}/, '* ').gsub(/{{\/listElement}}/, '')
    else
      # Link
      new_str = str.gsub(/\$\$LINK_DELIM\$\$/, ' ')
    end
    # Other
    new_str = new_str.gsub(/{{(#|\/)[A-Za-z]+}}/, '')
    # <, >
    new_str = new_str.gsub(/&lt;/, '<').gsub(/&gt;/, '>')
    return new_str
  end
end

