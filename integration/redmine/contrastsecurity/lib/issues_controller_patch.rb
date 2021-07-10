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
        res, msg = ContrastUtil.callAPI(url: url)
        # puts res.code
        if res.present? && res.code != "200"
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
        unless ContrastUtil.syncComment(org_id, app_id, vul_id, @issue)
          flash.now[:warning] = l(:sync_comment_failure)
        end
      else
        teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
        url = sprintf('%s/api/ng/%s/libraries/%s/%s?expand=vulns', teamserver_url, org_id, lib_lang, lib_id)
        res, msg = ContrastUtil.callAPI(url: url)
        # puts res.code
        if res.present? && res.code != "200"
          flash.now[:warning] = l(:lib_does_not_exist)
          show = show_without_update
          return show
        end
      end
      show = show_without_update
      return show
    end
  end
end

