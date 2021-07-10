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

  @@mutex = Thread::Mutex.new

  CUSTOM_FIELDS = [
    l('contrast_custom_fields.rule'),
    l('contrast_custom_fields.category'),
    l('contrast_custom_fields.server'),
    l('contrast_custom_fields.module'),
    l('contrast_custom_fields.confidence'),
    l('contrast_custom_fields.severity'),
    l('contrast_custom_fields.last_seen'),
    l('contrast_custom_fields.first_seen'),
    l('contrast_custom_fields.lib_lang'),
    l('contrast_custom_fields.lib_id'),
    l('contrast_custom_fields.vul_id'),
    l('contrast_custom_fields.app_id'),
    l('contrast_custom_fields.org_id')
  ].freeze
  # /Contrast/api/ng/[ORG_ID]/traces/[APP_ID]/trace/[VUL_ID]
  TRACE_API_ENDPOINT = '%s/api/ng/%s/traces/%s/trace/%s?expand=servers,application'.freeze
  LIBRARY_DETAIL_API_ENDPOINT = '%s/api/ng/%s/libraries/%s/%s?expand=vulns'.freeze
  TEAM_SERVER_URL = Setting.plugin_contrastsecurity['teamserver_url']
  APP_INFO_API_ENDPOINT = '%s/api/ng/%s/applications/%s?expand=skip_links'.freeze

  def vote
    # logger.info(request.body.read)
    parsed_payload = ContrastPayloadParser.new(JSON.parse(request.body.read))

    # logger.info(event_type)

    project = Project.find_by_identifier(parsed_payload.project_id)
    tracker = Tracker.find_by_name(parsed_payload.tracker)

    if project.nil? || tracker.nil?
      return head :not_found
    end

    unless tracker.projects.include? project
      tracker.projects << project
      tracker.save
    end

    add_custom_fields = []
    if parsed_payload.event_type == 'NEW_VULNERABILITY' ||
       parsed_payload.event_type == 'VULNERABILITY_DUPLICATE'
      if parsed_payload.event_type == 'NEW_VULNERABILITY'
        logger.info(l(:event_new_vulnerability))
      else
        logger.info(l(:event_dup_vulnerability))
      end

      unless Setting.plugin_contrastsecurity['vul_issues']
        return render plain: 'Vul Skip'
      end

      url = format(TRACE_API_ENDPOINT,
                   TEAM_SERVER_URL,
                   parsed_payload.org_id,
                   parsed_payload.app_id,
                   parsed_payload.vul_id)

      res, msg = ContrastUtil.callAPI(url: url)
      vuln_json = JSON.parse(res.body)
      # logger.info(vuln_json)
      url = format(
        APP_INFO_API_ENDPOINT,
        TEAM_SERVER_URL,
        parsed_payload.org_id,
        parsed_payload.app_id
      )
      res, msg = ContrastUtil.callAPI(url: url)
      app_info_json = JSON.parse(res.body)

      summary = '[' + app_info_json['application']['name'] + '] ' + vuln_json['trace']['title']

      first_time_seen = vuln_json['trace']['first_time_seen']
      last_time_seen = vuln_json['trace']['last_time_seen']
      category = vuln_json['trace']['category']
      confidence = vuln_json['trace']['confidence']
      rule_title = vuln_json['trace']['rule_title']
      severity = vuln_json['trace']['severity']
      priority = ContrastUtil.get_priority_by_severity(severity)
      status = vuln_json['trace']['status']
      status_obj = ContrastUtil.get_redmine_status(status)
      # logger.info(priority)
      if priority.nil?
        logger.error(l(:problem_with_priority))
        return head :not_found
      end
      module_str = parsed_payload.app_name + ' (' + vuln_json['trace']['application']['context_path'] + ') - ' + vuln_json['trace']['application']['language']
      server_list = Array.new
      vuln_json['trace']['servers'].each do |c_server|
        server_list.push(c_server['name'])
      end
      dt_format = Setting.plugin_contrastsecurity['vul_seen_dt_format']
      if dt_format.blank?
        dt_format = '%Y/%m/%d %H:%M'
      end
      add_custom_fields << { 'id_str': l('contrast_custom_fields.first_seen'),
                             'value': Time.at(first_time_seen / 1000.0)
                                          .strftime(dt_format) }
      add_custom_fields << { 'id_str': l('contrast_custom_fields.last_seen'),
                             'value': Time.at(last_time_seen / 1000.0)
                                          .strftime(dt_format) }
      add_custom_fields << { 'id_str': l('contrast_custom_fields.severity'),
                             'value': severity }
      add_custom_fields << { 'id_str': l('contrast_custom_fields.confidence'),
                             'value': confidence }
      add_custom_fields << { 'id_str': l('contrast_custom_fields.module'),
                             'value': module_str }
      add_custom_fields << { 'id_str': l('contrast_custom_fields.server'),
                             'value': server_list.join(', ') }
      add_custom_fields << { 'id_str': l('contrast_custom_fields.category'),
                             'value': category }
      add_custom_fields << { 'id_str': l('contrast_custom_fields.rule'),
                             'value': rule_title }
      # logger.info(add_custom_fields)
      story_url = ''
      howtofix_url = ''
      vuln_json['trace']['links'].each do |c_link|
        if c_link['rel'] == 'story'
          story_url = c_link['href']
          if story_url.include?('{traceUuid}')
            story_url = story_url.sub(/{traceUuid}/, vul_id)
          end
        end
        if c_link['rel'] == 'recommendation'
          howtofix_url = c_link['href']
          if howtofix_url.include?('{traceUuid}')
            howtofix_url = howtofix_url.sub(/{traceUuid}/, vul_id)
          end
        end
      end
      # logger.info(summary)
      # logger.info(story_url)
      # logger.info(howtofix_url)
      # logger.info(self_url)
      # Story
      chapters = ''
      story = ''
      if story_url.present?
        get_story_res, msg = ContrastUtil.callAPI(url: story_url)
        story_json = JSON.parse(get_story_res.body)
        story_json['story']['chapters'].each do |chapter|
          chapters << chapter['introText'] + "\n"
          if chapter['type'] == 'properties'
            chapter['properties'].each do |key, value|
              chapters << "\n" + key + "\n"
              if value['value'].start_with?('{{#table}}')
                chapters << "\n" + value['value'] + "\n"
              else
                chapters << '{{#xxxxBlock}}' + value['value'] + "{{/xxxxBlock}}\n"
              end
            end
          elsif ['configuration', 'location', 'recreation', 'dataflow', 'source'].include? chapter['type']
            chapters << '{{#xxxxBlock}}' + chapter['body'] + "{{/xxxxBlock}}\n"
          end
        end
        story = story_json['story']['risk']['formattedText']
      end
      # How to fix
      howtofix = ''
      if howtofix_url.present?
        get_howtofix_res, msg = ContrastUtil.callAPI(url: howtofix_url)
        howtofix_json = JSON.parse(get_howtofix_res.body)
        howtofix = howtofix_json['recommendation']['formattedText']
      end
      # description
      deco_mae = ''
      deco_ato = ''
      if Setting.text_formatting == 'textile'
        deco_mae = 'h2. '
        deco_ato = "\n"
      elsif Setting.text_formatting == 'markdown'
        deco_mae = '## '
      end
      description = ''
      description << deco_mae + l(:report_vul_happened) + deco_ato + "\n"
      description << convertMustache(chapters) + "\n\n"
      description << deco_mae + l(:report_vul_overview) + deco_ato + "\n"
      description << convertMustache(story) + "\n\n"
      description << deco_mae + l(:report_vul_howtofix) + deco_ato + "\n"
      description << convertMustache(howtofix) + "\n\n"
      description << deco_mae + l(:report_vul_url) + deco_ato + "\n"
      description << parsed_payload.get_self_url
    elsif parsed_payload.event_type == 'VULNERABILITY_CHANGESTATUS_OPEN' ||
          parsed_payload.event_type == 'VULNERABILITY_CHANGESTATUS_CLOSED'
      logger.info(l(:event_vulnerability_changestatus))

      # logger.info(status)
      if parsed_payload.vul_id.blank?
        logger.error(l(:problem_with_customfield))
        return head :ok
      end
      cvs = CustomValue.where(
        customized_type: 'Issue', value: parsed_payload.vul_id
      ).joins(:custom_field).where(
        custom_fields: {
          name: l('contrast_custom_fields.vul_id')
        }
      )
      cvs.each do |cv|
        issue = cv.customized
        if parsed_payload.project_id != issue.project.identifier
          next
        end

        status_obj = ContrastUtil.get_redmine_status(parsed_payload.status)
        if status_obj.nil?
          logger.error(l(:problem_with_status))
          return head :ok
        end

        issue.status = status_obj
        if issue.save
          logger.info(l(:issue_status_change_success))
          return head :ok
        else
          logger.error(l(:issue_status_change_failure))
          return head :internal_server_error
        end
      end
      return head :ok
    elsif parsed_payload.event_type == 'NEW_VULNERABLE_LIBRARY'
      logger.info(l(:event_new_vulnerable_library))
      unless Setting.plugin_contrastsecurity['lib_issues']
        return render plain: 'Lib Skip'
      end

      lib_info = parsed_payload.get_lib_info
      # logger.info("[+]lib_info: #{lib_info}, #{lib_info['lang']}, #{lib_info['id'] }")
      url = format(LIBRARY_DETAIL_API_ENDPOINT,
                   TEAM_SERVER_URL, parsed_payload.org_id,
                   lib_info['lang'], lib_info['id'])
      # logger.info("LIBRARY_URL: #{url}")
      res, msg = ContrastUtil.callAPI(url: url)
      # logger.info(JSON.parse(res.body))
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
      # logger.info(priority)
      if priority.nil?
        logger.error(l(:problem_with_priority))
        return head :not_found
      end

      self_url = parsed_payload.get_lib_url
      summary = lib_name
      # description
      deco_mae = ''
      deco_ato = ''
      if Setting.text_formatting == 'textile'
        deco_mae = '*'
        deco_ato = '*'
      elsif Setting.text_formatting == 'markdown'
        deco_mae = '**'
        deco_ato = '**'
      end
      description = ''
      description << deco_mae + l(:report_lib_curver) + deco_ato + "\n"
      description << file_version + "\n\n"
      description << deco_mae + l(:report_lib_newver) + deco_ato + "\n"
      description << latest_version + "\n\n"
      description << deco_mae + l(:report_lib_class) + deco_ato + "\n"
      description << classes_used.to_s + '/' + class_count.to_s + "\n\n"
      description << deco_mae + l(:report_lib_cves) + deco_ato + "\n"
      description << cve_list.join("\n") + "\n\n"
      description << deco_mae + l(:report_lib_url) + deco_ato + "\n"
      description << self_url
    elsif parsed_payload.event_type == 'NEW_VULNERABILITY_COMMENT_FROM_SCRIPT'
      logger.info(l(:event_new_vulnerability_comment))

      if parsed_payload.set_vul_info_from_comment
        cvs = CustomValue.where(
          customized_type: 'Issue', value: parsed_payload.vul_id
        ).joins(:custom_field).where(
          custom_fields: { name: l('contrast_custom_fields.vul_id') }
        )
        cvs.each do |cv|
          issue = cv.customized
          if parsed_payload.project_id == issue.project.identifier
            ContrastUtil.syncComment(parsed_payload.org_id,
                                     parsed_payload.app_id,
                                     parsed_payload.vul_id,
                                     issue)
          end
        end
      end
      return head :ok
    else
      if parsed_payload.vulnerability_tags == 'VulnerabilityTestTag'
        return render plain: 'Test URL Success'
      end
      return head :ok
    end
    # ここに来るのは NEW_VULNERABILITY か VULNERABILITY_DUPLICATE か NEW_VULNERABLE_LIBRARYの通知のみです。
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
        unless custom_field.projects.include? project
          custom_field.projects << project
          custom_field.save
        end
        unless custom_field.trackers.include? tracker
          custom_field.trackers << tracker
          custom_field.save
        end
      end
      custom_field_hash[custom_field_name] = custom_field.id
    end
    # DUPLICATEの場合は脆弱性IDが違うもので飛んでくる場合があるので、取得し直す
    # LIBRARYの場合はvuln_idを取得し直さない
    vul_id = ''
    if parsed_payload.event_type != 'NEW_VULNERABLE_LIBRARY'
      url = "#{TEAM_SERVER_URL}/api/ng/#{parsed_payload.org_id}/traces/#{parsed_payload.app_id}/filter/#{parsed_payload.vul_id}"
      res, msg = ContrastUtil.callAPI(url: url)
      parsed_response = JSON.parse(res.body)
      vul_id = parsed_response['trace']['uuid']
    end
    lib_info = parsed_payload.get_lib_info
    custom_fields = [
      { 'id': custom_field_hash[l('contrast_custom_fields.org_id')],
        'value': parsed_payload.org_id },
      { 'id': custom_field_hash[l('contrast_custom_fields.app_id')],
        'value': parsed_payload.app_id },
      { 'id': custom_field_hash[l('contrast_custom_fields.vul_id')],
        'value': vul_id },
      { 'id': custom_field_hash[l('contrast_custom_fields.lib_id')],
        'value': lib_info['id'] },
      { 'id': custom_field_hash[l('contrast_custom_fields.lib_lang')],
        'value': lib_info['lang'] }
    ]
    add_custom_fields.each do |add_custom_field|
      custom_fields << { 'id': custom_field_hash[add_custom_field[:id_str]], 'value': add_custom_field[:value] }
    end
    # logger.info(custom_fields)
    issue = nil
    @@mutex.lock
    begin
      # 脆弱性ライブラリはDUPLICATE通知はない前提
      if parsed_payload.event_type != 'NEW_VULNERABLE_LIBRARY'
        # logger.info("[+]webhook vul_id: #{parsed_payload.vul_id}, api vul_id: #{vul_id}")
        cvs = CustomValue.where(
          customized_type: 'Issue', value: vul_id
        ).joins(:custom_field).where(
          custom_fields: { name: l('contrast_custom_fields.vul_id') }
        )
        # logger.info("[+]Custome Values: #{cvs}")
        cvs.each do |cv|
          logger.info(cv)
          issue = cv.customized
        end
      end
      if issue.nil?
        # logger.info("[+]event_type: #{parsed_payload.event_type}")
        # logger.info("[+] issue: #{issue}")
        issue = Issue.new(
          project: project,
          subject: summary,
          tracker: tracker,
          priority: priority,
          description: description,
          custom_fields: custom_fields,
          author: User.current
        )
      elsif parsed_payload.event_type == 'VULNERABILITY_DUPLICATE'
        logger.info('[+]update issue')
        issue.description = description
        issue.custom_fields = custom_fields
      end
    ensure
      @@mutex.unlock
    end
    unless status_obj.nil?
      issue.status = status_obj
    end
    if issue.save
      if parsed_payload.event_type == 'VULNERABILITY_DUPLICATE'
        logger.info(l(:issue_update_success))
      else
        logger.info(l(:issue_create_success))
      end
      return head :ok
    else
      if parsed_payload.event_type == 'VULNERABILITY_DUPLICATE'
        logger.error(l(:issue_update_failure))
      else
        logger.error(l(:issue_create_failure))
      end
      return head :internal_server_error
    end
  end

  def convertMustache(str)
    if Setting.text_formatting == 'textile'
      # Link
      new_str = str.gsub(/({{#link}}[^\[]+?)\[\](.+?\$\$LINK_DELIM\$\$)/, '\1%5B%5D\2')
      new_str = new_str.gsub(%r{{{#link}}(.+?)\$\$LINK_DELIM\$\$(.+?){{/link}}}, '"\2":\1 ')
      # CodeBlock
      new_str = new_str.gsub(/{{#[A-Za-z]+Block}}/, '<pre>').gsub(%r{{{/[A-Za-z]+Block}}}, '</pre>')
      # Header
      new_str = new_str.gsub(/{{#header}}/, 'h3. ').gsub(%r{{{/header}}}, "\n")
      # List
      new_str = new_str.gsub(/[ \t]*{{#listElement}}/, '* ').gsub(%r{{{/listElement}}}, '')
      # Table
      while true do
        tbl_bgn_idx = new_str.index('{{#table}}')
        tbl_end_idx = new_str.index('{{/table}}')
        if tbl_bgn_idx.nil? || tbl_end_idx.nil?
          break
        else
          # logger.info(sprintf('%s - %s', tbl_bgn_idx, tbl_end_idx))
          tbl_str = new_str.slice(tbl_bgn_idx, tbl_end_idx - tbl_bgn_idx + 10) # 10は{{/table}}の文字数
          tbl_str = tbl_str.gsub(/[ \t]*{{#tableRow}}[\s]*{{#tableHeaderRow}}/, '|').gsub(%r{{{/tableHeaderRow}}[\s]*}, '|')
          tbl_str = tbl_str.gsub(/[ \t]*{{#tableRow}}[\s]*{{#tableCell}}/, '|').gsub(%r{{{/tableCell}}[\s]*}, '|')
          tbl_str = tbl_str.gsub(/[ \t]*{{#badTableRow}}[\s]*{{#tableCell}}/, "\n|").gsub(%r{{{/tableCell}}[\s]*}, '|')
          tbl_str = tbl_str.gsub(/{{{nl}}}/, '<br>')
          tbl_str = tbl_str.gsub(%r{{{(#|/)[A-Za-z]+}}}, '') # ここで残ったmustacheを全削除
          new_str[tbl_bgn_idx, tbl_end_idx - tbl_bgn_idx + 10] = tbl_str # 10は{{/table}}の文字数
        end
      end
    elsif Setting.text_formatting == 'markdown'
      # Link
      new_str = str.gsub(/({{#link}}[^\[]+?)\[\](.+?\$\$LINK_DELIM\$\$)/, '\1%5B%5D\2')
      new_str = new_str.gsub(%r{{{#link}}(.+?)\$\$LINK_DELIM\$\$(.+?){{/link}}}, '[\2](\1)')
      # CodeBlock
      new_str = new_str.gsub(/{{#[A-Za-z]+Block}}/, "\n~~~\n").gsub(%r{{{/[A-Za-z]+Block}}}, "\n~~~\n")
      # Header
      new_str = new_str.gsub(/{{#header}}/, '### ').gsub(%r{{{/header}}}, '')
      # List
      new_str = new_str.gsub(/[ \t]*{{#listElement}}/, '* ').gsub(%r{{{/listElement}}}, '')
      # Table
      while true do
        tbl_bgn_idx = new_str.index('{{#table}}')
        tbl_end_idx = new_str.index('{{/table}}')
        if tbl_bgn_idx.nil? || tbl_end_idx.nil?
          break
        else
          # logger.info(sprintf('%s - %s', tbl_bgn_idx, tbl_end_idx))
          tbl_str = new_str.slice(tbl_bgn_idx, tbl_end_idx - tbl_bgn_idx + 10) # 10は{{/table}}の文字数
          tbl_str = tbl_str.gsub(%r{({{#tableRow}}[\s]*({{#tableHeaderRow}}.+{{/tableHeaderRow}})[\s]*{{/tableRow}})}, '\1' + "\n{{#tableRowX}}" + '\2' + '{{/tableRowX}}')
          if mo = tbl_str.match(%r{({{#tableRowX}}[\s]*.+[\s]*{{/tableRowX}})})
            replace_str = mo[1].gsub(/tableHeaderRow/, 'tableHeaderRowX')
            tbl_str = tbl_str.gsub(%r{{{#tableRowX}}[\s]*.+[\s]*{{/tableRowX}}}, replace_str)
            tbl_str = tbl_str.gsub(%r{({{#tableHeaderRowX}})(.+?)({{/tableHeaderRowX}})}, '\1---\3')
          end
          tbl_str = tbl_str.gsub(/[ \t]*{{#tableRow}}[\s]*{{#tableHeaderRow}}/, '|').gsub(%r{{{/tableHeaderRow}}[\s]*}, '|')
          tbl_str = tbl_str.gsub(/[ \t]*{{#tableRowX}}[\s]*{{#tableHeaderRowX}}/, '|').gsub(%r{{{/tableHeaderRowX}}[\s]*}, '|')
          tbl_str = tbl_str.gsub(/[ \t]*{{#tableRow}}[\s]*{{#tableCell}}/, '|').gsub(%r{{{/tableCell}}[\s]*}, '|')
          tbl_str = tbl_str.gsub(/[ \t]*{{#badTableRow}}[\s]*{{#tableCell}}/, "\n|").gsub(%r{{{/tableCell}}[\s]*}, '|')
          tbl_str = tbl_str.gsub(/{{{nl}}}/, '<br>')
          tbl_str = tbl_str.gsub(%r{{{(#|/)[A-Za-z]+}}}, '') # ここで残ったmustacheを全削除
          new_str[tbl_bgn_idx, tbl_end_idx - tbl_bgn_idx + 10] = tbl_str # 10は{{/table}}の文字数
        end
      end
    else
      # Link
      new_str = str.gsub(/\$\$LINK_DELIM\$\$/, ' ')
    end
    # New line
    new_str = new_str.gsub(/{{{nl}}}/, "\n")
    # Other
    new_str = new_str.gsub(%r{{{(#|/)[A-Za-z]+}}}, '')
    # Comment
    new_str = new_str.gsub(/{{!.+}}/, '')
    # <, >, nbsp
    new_str = new_str.gsub(/&lt;/, '<').gsub(/&gt;/, '>').gsub(/&nbsp;/, ' ')
    # Quot
    new_str = new_str.gsub(/&quot;/, '"')
    # Tab
    new_str = new_str.gsub(/\t/, '    ')
    # Character Reference
    new_str = new_str.gsub(/&#[^;]+;/, '')
    return new_str
  end
end

