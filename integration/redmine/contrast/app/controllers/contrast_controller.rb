class ContrastController < ApplicationController
  before_action :require_login
  skip_before_filter :verify_authenticity_token
  accept_api_auth :vote

  CUSTOM_FIELDS = ['contrast_org_id', 'contrast_app_id', 'contrast_vul_id', 'contrast_lib_id'].freeze

  def vote
    #logger.info(request.body.read)
    t_issue = JSON.parse(request.body.read)
    #logger.info(t_issue['description'])
    project_identifier = t_issue['project']
    tracker_str = t_issue['tracker']
    project = Project.find_by_identifier(project_identifier)
    tracker = Tracker.find_by_name(tracker_str)
    priority = IssuePriority.default
    if t_issue.has_key?('priority')
      priority_str = t_issue['priority'].gsub(/\\u([\da-fA-F]{4})/){[$1].pack('H*').unpack('n*').pack('U*')}
      priority = IssuePriority.find_by_name(priority_str)
    end
    logger.info(priority)
    if project.nil? || tracker.nil? || priority.nil?
      return head :not_found
    end
    vul_pattern = /index.html#\/(.+)\/applications\/(.+)\/vulns\/(.+)\) was found in/
    lib_pattern = /.+ was found in ([^(]+) \(.+index.html#\/(.+)\/.+\/(.+)\/([^)]+)\),.+\/applications\/([^)]+)\)./
    is_vul = t_issue['description'].match(vul_pattern)
    is_lib = t_issue['description'].match(lib_pattern)
    if is_vul
      if not Setting.plugin_contrast['vul_issues']
        return render plain: 'Vul Skip'
      end
      org_id = is_vul[1]
      app_id = is_vul[2]
      vul_id = is_vul[3]
      lib_id = ''
      # /Contrast/api/ng/[ORG_ID]/traces/[APP_ID]/trace/[VUL_ID]
      teamserver_url = Setting.plugin_contrast['teamserver_url']
      url = sprintf('%s/api/ng/%s/traces/%s/trace/%s', teamserver_url, org_id, app_id, vul_id)
      logger.info(url)
      get_data = callAPI('GET', url, false)
      vuln_json = JSON.parse(get_data)
      summary = vuln_json['trace']['title']
      story_url = ''
      howtofix_url = ''
      self_url = ''
      vuln_json['trace']['links'].each do |c_link|
        if c_link['rel'] == 'self'
          self_url = c_link['href']
        end
        if c_link['rel'] == 'story'
          story_url = c_link['href']
        end
        if c_link['rel'] == 'recommendation'
          howtofix_url = c_link['href']
        end
      end
      logger.info(summary)
      logger.info(story_url)
      logger.info(howtofix_url)
      logger.info(self_url)
      # Story
      get_story_data = callAPI('GET', story_url, false)
      story_json = JSON.parse(get_story_data)
      story = story_json['story']['risk']['text']
      # How to fix
      get_howtofix_data = callAPI('GET', howtofix_url, false)
      howtofix_json = JSON.parse(get_howtofix_data)
      howtofix = howtofix_json['recommendation']['text']
      # description
      description = ""
      description << "概要\n"
      description << story + "\n\n"
      description << "修正方法\n"
      description << howtofix + "\n\n"
      description << "脆弱性URL\n"
      description << self_url
    elsif is_lib
      if not Setting.plugin_contrast['lib_issues']
        return render plain: 'Lib Skip'
      end
      lib_name = is_lib[1]
      org_id = is_lib[2]
      app_id = is_lib[5]
      vul_id = ''
      lang = is_lib[3]
      lib_id = is_lib[4]
      teamserver_url = Setting.plugin_contrast['teamserver_url']
      url = sprintf('%s/api/ng/%s/libraries/%s/%s?expand=vulns', teamserver_url, org_id, lang, lib_id)
      get_data = callAPI('GET', url, false)
      lib_json = JSON.parse(get_data)
      file_version = lib_json['library']['file_version']
      latest_version = lib_json['library']['latest_version']
      classes_used = lib_json['library']['classes_used']
      class_count = lib_json['library']['class_count']
      cve_list = Array.new
      lib_json['library']['vulns'].each do |c_link|
          cve_list.push(c_link['name'])
      end
      liburl_pattern = /.+ was found in .+\((.+)\),.+/
      is_liburl = t_issue['description'].match(liburl_pattern)
      self_url = ''
      if is_liburl
          self_url = is_liburl[1]
      end
      summary = lib_name
      description = ""
      description << "現在バージョン\n"
      description << file_version + "\n"
      description << "最新バージョン\n"
      description << latest_version + "\n"
      description << "クラス(使用/全体)\n"
      description << classes_used.to_s + "/" + class_count.to_s + "\n"
      description << "脆弱性\n"
      description << cve_list.join("\n") + "\n"
      description << "脆弱性URL\n"
      description << self_url
    else
        return render plain: 'Test URL Success'
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
      end
      custom_field_hash[custom_field_name] = custom_field.id
    end
    issue = Issue.new(
      project: project,
      subject: summary,
      tracker: tracker,
      priority: priority,
      description: description,
      custom_fields: [
        {'id': custom_field_hash['contrast_org_id'], 'value': org_id},
        {'id': custom_field_hash['contrast_app_id'], 'value': app_id},
        {'id': custom_field_hash['contrast_vul_id'], 'value': vul_id},
        {'id': custom_field_hash['contrast_lib_id'], 'value': lib_id}
      ],
      author: User.current
    )
    if issue.save
      logger.info('ok')
      return head :ok
    else
      logger.info('internal_server_error')
      return head :internal_server_error
    end
  end

  def callAPI(method, url, data)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    case method
      when 'POST'
        req = Net::HTTP::Post.new(uri.request_uri)
        req.body = data.to_json
      when 'PUT'
        req = Net::HTTP::Put.new(uri.request_uri)
      else
        req = Net::HTTP::Get.new(uri.request_uri)
    end
    req = Net::HTTP::Get.new(uri.request_uri)
    req["Authorization"] = Setting.plugin_contrast['auth_header']
    req["API-Key"] = Setting.plugin_contrast['api_key']
    req['Content-Type'] = req['Accept'] = 'application/json'
    res = http.request(req)
    return res.body
  end
end

