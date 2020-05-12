class ContrastController < ApplicationController
  before_action :require_login
  skip_before_filter :verify_authenticity_token
  accept_api_auth :vote

  def vote
    teamserver_url = Setting.plugin_contrast['teamserver_url']
    #logger.info(request.body.read)
    t_issue = JSON.parse(request.body.read)
    logger.info(t_issue)
    is_vul = t_issue['description'].match('/index.html#\/(.+)\/applications\/(.+)\/vulns\/(.+)\) was found in/')
    is_lib = t_issue['description'].match('/.+ was found in ([^(]+) \(.+index.html#\/(.+)\/.+\/(.+)\/([^)]+)\),.+\/applications\/([^)]+)\)./')
    if is_vul then
      if Setting.plugin_contrast['vul_issues'] then
        return render plain: 'Vul Skip'
      end
    elsif is_lib then
      if Setting.plugin_contrast['lib_issues'] then
        return render plain: 'Lib Skip'
      end
    else
        return render plain: 'Test URL Success'
    end
    personal = {'name' => 'Yamada', 'old' => 28}
    render :json => personal
  end
end

