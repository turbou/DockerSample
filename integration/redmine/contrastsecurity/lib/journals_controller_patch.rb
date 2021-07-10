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

module JournalsControllerPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method_chain :update, :sync
    end
  end

  module InstanceMethods
    def update_with_sync
      notes = @journal.notes
      @journal.safe_attributes = params[:journal]
      if @journal.notes.blank? # コメントが削除された場合
        issue = @journal.journalized
        cv_org = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.org_id')}).first
        cv_app = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.app_id')}).first
        cv_vul = CustomValue.where(customized_type: 'Issue').where(customized_id: issue.id).joins(:custom_field).where(custom_fields: {name: l('contrast_custom_fields.vul_id')}).first
        org_id = cv_org.try(:value)
        app_id = cv_app.try(:value)
        vul_id = cv_vul.try(:value)
        if org_id.nil? || org_id.empty? || app_id.nil? || app_id.empty? || vul_id.nil? || vul_id.empty?
          update = update_without_sync
          return update
        end
        note_id = nil
        @journal.details.each do |detail|
          if detail.prop_key == "contrast_note_id"
            note_id = detail.value
          end
        end
        if note_id.blank?
          update = update_without_sync
          return update
        end
        teamserver_url = Setting.plugin_contrastsecurity['teamserver_url']
        url = sprintf('%s/api/ng/%s/applications/%s/traces/%s/notes/%s?expand=skip_links', teamserver_url, org_id, app_id, vul_id, note_id)
        res, msg = ContrastUtil.callAPI(url: url, method: "DELETE")
        if res.present? && res.code == "200"
          @journal.details = []
        end
      end
      update = update_without_sync
      return update
    end
  end
end

