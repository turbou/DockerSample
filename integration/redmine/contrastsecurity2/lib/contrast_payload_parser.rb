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

# Contrast webhook's payload parser class
class ContrastPayloadParser
  UUID_V4_PATTERN = /[a-z0-9]{8}-[a-z0-9]{4}-4[a-z0-9]{3}-[a-z0-9]{4}-[a-z0-9]{12}/
                    .freeze
  VUL_ID_PATTERN = /[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}/.freeze
  VUL_ID_PATTERN2 = /[A-Z0-9\-]{19}$/.freeze
  VUL_URL_PATTERN = %r{.+\((.+/vulns/[A-Z0-9\-]{19})\)}.freeze

  attr_reader :event_type,
              :app_name,
              :app_id,
              :org_id,
              :vul_id,
              :lib_id,
              :description,
              :status,
              :vulnerability_tags,
              :project_id, # Redmine's project id
              :tracker #  name of Redmine's tracker

  def initialize(payload)
    @event_type = payload['event_type']
    @app_name = payload['application_name']
    @org_id = set_org_id(payload['organization_id'], payload['description'])
    @app_id = set_app_id(payload['application_id'], payload['description'])
    @vul_id = set_vul_id(payload['vulnerability_id'], payload['description'])
    @description = payload['description']
    @status = payload['status']
    @lib_id = ''
    @vulnerability_tags = payload['vulnerability_tags']
    @project_identifier = payload['project']
    @tracker = payload['tracker']
  end

  def self.set_org_id(org_id, description)
    unless org_id
      @org_id = description.scan(UUID_V4_PATTERN)[0]
      return
    end
    @org_id = org_id
  end

  def self.set_app_id(app_id, description)
    unless app_id
      @app_id = description.scan(UUID_V4_PATTERN)[1]
      return
    end
    @app_id = app_id
  end

  def self.set_vul_id(vul_id, description)
    unless vul_id
      @vul_id = description.scan(VUL_ID_PATTERN)[0]
      return
    end
    @vul_id = vul_id
  end

  def get_self_url
    is_vul_url = @description.match(VUL_URL_PATTERN)
    return is_vul_url[1].gsub(VUL_ID_PATTERN, @vul_id) if is_vul_url
  end

  def get_lib_info
    lib_pattern = %r{index.html#/#{@org_id}/libraries/(.+)/([a-z0-9]+)\)}
    matched = @description.match(lib_pattern)
    { 'lang': matched[1], 'id': matched[2] }
  end

  def get_lib_url
    lib_id = get_lib_info['id']
    lib_url_pattern = /.+\((.+#{lib_id})\)/
    @description.match(lib_url_pattern)[1]
  end

  def set_vul_info_from_comment
    vul_id_pattern = %r{.+ commented on a .+[^(]+ \(.+index.html#/(.+)/applications/(.+)/vulns/([^)]+)\)}
    matched = @description.match(vul_id_pattern)
    if matched
      set_org_id(matched[1], @description)
      set_app_id(matched[2], @description)
      set_vul_id(matched[3], @description)
    else
      false
    end
  end

end
