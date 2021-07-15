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

Redmine::Plugin.register :contrastsecurity do
  name 'Contrast plugin'
  author 'Taka Shiozaki'
  description 'This is a Contrast plugin for Redmine'
  version '1.2.1'
  url 'https://github.com/turbou/ContrastSecurity/tree/master/integration/redmine/contrastsecurity'
  author_url 'https://github.com/turbou'
  settings :default => {
    'vul_issues' => true,
    'lib_issues' => true,
    'vul_seen_dt_format' => '%Y/%m/%d %H:%M',
    'sts_reported' => '報告済',
    'sts_suspicious' => '疑わしい',
    'sts_confirmed' => '確認済',
    'sts_notaproblem' => '問題無し',
    'sts_remediated' => '修復済',
    'sts_fixed' => '修正完了',
    'pri_critical' => '最高',
    'pri_high' => '高',
    'pri_medium' => '中',
    'pri_low' => '低',
    'pri_note' => '最低',
    'pri_cvelib' => '高'
  }, :partial => 'settings/contrast_settings'
  require 'issue_hooks'
end

Rails.configuration.to_prepare do
  unless IssuesController.included_modules.include?(IssuesControllerPatch)
    IssuesController.send :include, IssuesControllerPatch
  end
  unless JournalsController.included_modules.include?(JournalsControllerPatch)
    JournalsController.send :include, JournalsControllerPatch
  end
  unless SettingsController.included_modules.include?(SettingsControllerPatch)
    SettingsController.send :include, SettingsControllerPatch
  end
  unless JournalsHelper.included_modules.include?(JournalsHelperPatch)
    JournalsHelper.send :include, JournalsHelperPatch
  end
end

