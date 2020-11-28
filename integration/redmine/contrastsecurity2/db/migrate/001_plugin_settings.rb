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

class PluginSettings < ActiveRecord::Migration

  CUSTOM_FIELD_NAMES = [
    '【Contrast】ルール名',
    '【Contrast】カテゴリ',
    '【Contrast】サーバ',
    '【Contrast】モジュール',
    '【Contrast】信頼性',
    '【Contrast】深刻度',
    '【Contrast】最後の検出',
    '【Contrast】最初の検出',
    '【Contrast】ライブラリ言語',
    '【Contrast】ライブラリID',
    '【Contrast】脆弱性ID',
    '【Contrast】アプリID',
    '【Contrast】組織ID'
  ]
  STATUS_NAMES = ['報告済', '疑わしい', '確認済', '問題無し', '修復済', '修正完了']
  PRIORITY_NAMES = ['最低', '低', '中', '高', '最高']

  def self.up
    puts "Status create..."
    STATUS_NAMES.each do |name|
      if not IssueStatus.exists?(name: name)
        IssueStatus.new(name: name, is_closed: false).save
      end
    end

    puts "Priority create..."
    PRIORITY_NAMES.each do |name|
      if not IssuePriority.exists?(name: name)
        IssuePriority.new(name: name, is_default: false, active: true).save
      end
    end

    puts "Tracker create..."
    if not Tracker.exists?(name: '脆弱性')
      tracker = Tracker.new(name: '脆弱性')
      tracker.default_status = IssueStatus.find_by_name('報告済')
      tracker.save
    end

    puts "CustomField create..."
    tracker = Tracker.find_by_name('脆弱性')
    CUSTOM_FIELD_NAMES.each do |name|
      if not IssueCustomField.exists?(name: name)
        custom_field = IssueCustomField.new(name: name)
        custom_field.position = 1
        custom_field.visible = true
        custom_field.is_required = false
        custom_field.is_filter = false
        custom_field.searchable = false
        custom_field.field_format = 'string'
        custom_field.trackers << tracker
        custom_field.save
      end
    end
  end

  def self.down
    puts "CustomField destroy..."
    CUSTOM_FIELD_NAMES.each do |name|
      if IssueCustomField.exists?(name: name)
        IssueCustomField.find_by_name(name).destroy
      end
    end

    puts "Tracker destroy..."
    if Tracker.exists?(name: '脆弱性')
      Tracker.find_by_name('脆弱性').destroy
    end

    puts "Priority destroy..."
    PRIORITY_NAMES.each do |name|
      if IssuePriority.exists?(name: name)
        IssuePriority.find_by_name(name).destroy
      end
    end

    puts "Status destroy..."
    STATUS_NAMES.each do |name|
      if IssueStatus.exists?(name: name)
        IssueStatus.find_by_name(name).destroy
      end
    end
  end
end

