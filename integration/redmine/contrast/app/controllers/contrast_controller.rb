class ContrastController < ApplicationController
  before_action :require_login
  skip_before_filter :verify_authenticity_token
  accept_api_auth :vote

  def vote
    #logger.info(request.body.read)
    t_issue = JSON.parse(request.body.read)
    #logger.info(t_issue['description'])
    project_identifier = t_issue['project']['name']
    project = Project.find_by_identifier(project_identifier)
    if project.nil? then
      return head :not_found
    end
    logger.info(project.id)
    issue = Issue.new(project: project, subject: 'Sample')
    issue.save
    vul_pattern = /index.html#\/(.+)\/applications\/(.+)\/vulns\/(.+)\) was found in/
    lib_pattern = /.+ was found in ([^(]+) \(.+index.html#\/(.+)\/.+\/(.+)\/([^)]+)\),.+\/applications\/([^)]+)\)./
    is_vul = t_issue['description'].match(vul_pattern)
    is_lib = t_issue['description'].match(lib_pattern)
    if is_vul then
      if not Setting.plugin_contrast['vul_issues'] then
        return render plain: 'Vul Skip'
      end
      org_id = is_vul[1];
      app_id = is_vul[2];
      vul_id = is_vul[3];
      lib_id = "";
      # /Contrast/api/ng/[ORG_ID]/traces/[APP_ID]/trace/[VUL_ID]
      teamserver_url = Setting.plugin_contrast['teamserver_url']
      url = sprintf('%s/api/ng/%s/traces/%s/trace/%s', teamserver_url, org_id, app_id, vul_id);
      logger.info(url)
      get_data = callAPI('GET', url, false)
      vuln_json = JSON.parse(get_data)
      summary = vuln_json['trace']['title']
      story_url = ''
      howtofix_url = ''
      self_url = ''
      vuln_json['trace']['links'].each do |c_link|
        if c_link['rel'] == 'self' then
          self_url = c_link['href']
        end
        if c_link['rel'] == 'story' then
          story_url = c_link['href']
        end
        if c_link['rel'] == 'recommendation' then
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
      story = story_json['story']['risk']['text'];
      # How to fix
      get_howtofix_data = callAPI('GET', howtofix_url, false);
      howtofix_json = JSON.parse(get_howtofix_data)
      howtofix = howtofix_json['recommendation']['text'];
    elsif is_lib then
      if not Setting.plugin_contrast['lib_issues'] then
        return render plain: 'Lib Skip'
      end
    else
        return render plain: 'Test URL Success'
    end
    personal = {'name' => 'Yamada', 'old' => 28}
    render :json => personal
  end

  def callAPI(method, url, data)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    case method
      when 'POST' then
        req = Net::HTTP::Post.new(uri.request_uri)
        req.body = data.to_json
      when 'PUT' then
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

