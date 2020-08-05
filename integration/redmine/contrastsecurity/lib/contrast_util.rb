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

module ContrastUtil
  def self.get_priority_by_severity(severity)
    case severity
    when "Critical"
      priority_str = Setting.plugin_contrastsecurity['pri_critical']
    when "High"
      priority_str = Setting.plugin_contrastsecurity['pri_high']
    when "Medium"
      priority_str = Setting.plugin_contrastsecurity['pri_medium']
    when "Low"
      priority_str = Setting.plugin_contrastsecurity['pri_low']
    when "Note"
      priority_str = Setting.plugin_contrastsecurity['pri_note']
    end 
    priority = IssuePriority.find_by_name(priority_str)
    return priority
  end

  def self.get_redmine_status(contrast_status)
    case contrast_status
    when "Reported"
      rm_status = Setting.plugin_contrastsecurity['sts_reported']
    when "Suspicious"
      rm_status = Setting.plugin_contrastsecurity['sts_suspicious']
    when "Confirmed"
      rm_status = Setting.plugin_contrastsecurity['sts_confirmed']
    when "NotAProblem", "Not a Problem"
      rm_status = Setting.plugin_contrastsecurity['sts_notaproblem']
    when "Remediated"
      rm_status = Setting.plugin_contrastsecurity['sts_remediated']
    when "Fixed"
      rm_status = Setting.plugin_contrastsecurity['sts_fixed']
    end 
    status = IssueStatus.find_by_name(rm_status)
    return status
  end

  def self.get_contrast_status(redmine_status)
    sts_reported_array = [Setting.plugin_contrastsecurity['sts_reported']]
    sts_suspicious_array = [Setting.plugin_contrastsecurity['sts_suspicious']]
    sts_confirmed_array = [Setting.plugin_contrastsecurity['sts_confirmed']]
    sts_notaproblem_array = [Setting.plugin_contrastsecurity['sts_notaproblem']]
    sts_remediated_array = [Setting.plugin_contrastsecurity['sts_remediated']]
    sts_fixed_array = [Setting.plugin_contrastsecurity['sts_fixed']]
    status = nil
    if sts_reported_array.include?(redmine_status)
      status = "Reported"
    elsif sts_suspicious_array.include?(redmine_status)
      status = "Suspicious"
    elsif sts_confirmed_array.include?(redmine_status)
      status = "Confirmed"
    elsif sts_notaproblem_array.include?(redmine_status)
      status = "NotAProblem"
    elsif sts_remediated_array.include?(redmine_status)
      status = "Remediated"
    elsif sts_fixed_array.include?(redmine_status)
      status = "Fixed"
    end
    return status
  end
end

