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
      cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】組織ID'}).first
      cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】アプリID'}).first
      cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: @issue.id).joins(:custom_field).where(custom_fields: {name: '【Contrast】脆弱性ID'}).first
      org_id = cv_org.try(:value)
      app_id = cv_app.try(:value)
      vul_id = cv_vul.try(:value)
      if org_id.nil? || org_id.empty? || app_id.nil? || app_id.empty? || vul_id.nil? || vul_id.empty?
        show = show_without_update
        return show
      end 
  
      teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
      url = sprintf('%s/api/ng/%s/traces/%s/trace/%s', teamserver_url, org_id, app_id, vul_id)
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      req = Net::HTTP::Get.new(uri.request_uri)
      req["Authorization"] = Setting.plugin_contrastsecurity['auth_header']
      req["API-Key"] = Setting.plugin_contrastsecurity['api_key']
      req['Content-Type'] = req['Accept'] = 'application/json'
      res = http.request(req)
      vuln_json = JSON.parse(res.body)
      last_time_seen = vuln_json['trace']['last_time_seen']
      @issue.custom_field_values.each do |cfv|
        if cfv.custom_field.name == '【Contrast】最後の検出' then
          cfv.value = Time.at(last_time_seen/1000.0).strftime('%Y-%m-%dT%H:%M:%S.%LZ')
        end 
      end 
      @issue.save
      show = show_without_update
      return show
    end
  end
end

