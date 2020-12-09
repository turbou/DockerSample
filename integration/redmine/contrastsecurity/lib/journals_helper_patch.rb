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

module JournalsHelperPatch
  def self.included(base)
    base.send(:include, InstanceMethods)
    base.class_eval do
      unloadable
      alias_method_chain :render_notes, :modify
    end
  end

  module InstanceMethods
    def render_notes_with_modify(issue, journal, options={})
      render_notes = render_notes_without_modify(issue, journal, options)
      last_updater_uid = nil 
      last_updater = nil 
      journal.details.each do |detail|
        if detail.prop_key == "contrast_last_updater_uid"
          last_updater_uid = detail.value
        elsif detail.prop_key == "contrast_last_updater"
          last_updater = detail.value
        end 
      end 
      if last_updater_uid.blank?
        # おそらくContrastと無関係なチケット
        return render_notes
      end
      username = Setting.plugin_contrastsecurity['username']
      if last_updater_uid != username
        upd_tag = link_to(l(:button_edit),
                          edit_journal_path(journal),
                          :remote => true,
                          :method => 'get',
                          :title => l(:button_edit),
                          :class => 'icon-only icon-edit'
                         ).html_safe
        del_tag = link_to(l(:button_delete),
                          journal_path(journal, :journal => {:notes => ""}),
                          :remote => true,
                          :method => 'put', :data => {:confirm => l(:text_are_you_sure)}, 
                          :title => l(:button_delete),
                          :class => 'icon-only icon-del'
                         ).html_safe
        return render_notes.gsub(upd_tag, "").gsub(del_tag, "").gsub("</p></div>", "</p><i>by " + last_updater + "</i></div>").html_safe
      else
        exist_creator_pattern = /(\(by .+\))<\/p>/
        is_exist_creator = render_notes.match(exist_creator_pattern)
        if is_exist_creator
          by_creator = is_exist_creator[1].gsub(/\(|\)/, "")
          return render_notes.gsub(is_exist_creator[1], "").gsub("</p></div>", "</p><i>" + by_creator + "</i></div>").html_safe
        end
      end
      return render_notes
    end
  end
end

