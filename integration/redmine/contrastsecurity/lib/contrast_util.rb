module ContrastUtil
  def self.get_priority_by_severity(severity)
    if 'Critical' == severity
      priority_str = Setting.plugin_contrastsecurity['pri_critical']
    elsif 'High' == severity
      priority_str = Setting.plugin_contrastsecurity['pri_high']
    elsif 'Medium' == severity
      priority_str = Setting.plugin_contrastsecurity['pri_medium']
    elsif 'Low' == severity
      priority_str = Setting.plugin_contrastsecurity['pri_low']
    elsif 'Note' == severity
      priority_str = Setting.plugin_contrastsecurity['pri_note']
    end 
    priority = IssuePriority.find_by_name(priority_str)
    return priority
  end

  def self.get_redmine_status(contrast_status)
    if 'Reported' == contrast_status
      rm_status = Setting.plugin_contrastsecurity['sts_reported']
    elsif 'Suspicious' == contrast_status
      rm_status = Setting.plugin_contrastsecurity['sts_suspicious']
    elsif 'Confirmed' == contrast_status
      rm_status = Setting.plugin_contrastsecurity['sts_confirmed']
    elsif 'NotAProblem' == contrast_status
      rm_status = Setting.plugin_contrastsecurity['sts_notaproblem']
    elsif 'Remediated' == contrast_status
      rm_status = Setting.plugin_contrastsecurity['sts_remediated']
    elsif 'Fixed' == contrast_status
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

