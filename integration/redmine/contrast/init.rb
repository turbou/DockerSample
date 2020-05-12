Redmine::Plugin.register :contrast do
  name 'Contrast plugin'
  author 'Taka Shiozaki'
  description 'This is a Contrast plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
  settings :default => {'vul_issues' => true, 'lib_issues' => true}, :partial => 'settings/contrast_settings'
end
