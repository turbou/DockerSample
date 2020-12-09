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
  UUID_V4_PATTERN = /[a-z0-9]{8}-[a-z0-9]{4}-4[a-z0-9]{3}-[a-z0-9]{4}-[a-z0-9]{12}/.freeze
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
    @org_id = ContrastPayloadParser.parse_org_id(payload['organization_id'],
                                                 payload['description'])
    @app_id = ContrastPayloadParser.parse_app_id(payload['application_id'],
                                                 payload['description'])
    @vul_id = ContrastPayloadParser.parse_vul_id(payload['vulnerability_id'],
                                                 payload['description'])
    @description = payload['description']
    @status = payload['status']
    @lib_id = ''
    @vulnerability_tags = payload['vulnerability_tags']
    @project_id = payload['project']
    @tracker = payload['tracker']
  end

  def self.parse_org_id(org_id, description)
    if org_id.empty?
      description.scan(UUID_V4_PATTERN)[0]
    else
      org_id
    end
  end

  def self.parse_app_id(app_id, description)
    if app_id.empty?
      description.scan(UUID_V4_PATTERN)[1]
    else
      app_id
    end
  end

  def self.parse_vul_id(vul_id, description)
    if vul_id.empty?
      description.scan(VUL_ID_PATTERN)[0]
    else
      vul_id
    end
  end

  def get_self_url
    is_vul_url = @description.match(VUL_URL_PATTERN)
    return is_vul_url[1].gsub(VUL_ID_PATTERN, @vul_id) if is_vul_url
  end

  def get_lib_info
    lib_pattern = %r{index.html#/#{@org_id}/libraries/(.+)/([a-z0-9]+)\)}
    matched = @description.match(lib_pattern)

    if matched
      @lib_id = matched[2]
      return { 'lang' => matched[1], 'id' => matched[2] }
    else
      return { 'lang' => '', 'id' => '' }
    end
  end

  def get_lib_url
    lib_info = get_lib_info
    lib_url_pattern = /.+\((.+#{lib_info['id']})\)/
    @description.match(lib_url_pattern)[1]
  end

  def set_vul_info_from_comment
    vul_id_pattern = %r{.+ commented on a .+[^(]+ \(.+index.html#/(.+)/applications/(.+)/vulns/([^)]+)\)}
    matched = @description.match(vul_id_pattern)
    if matched
      ContrastPayloadParser.parse_org_id(matched[1], @description)
      ContrastPayloadParser.parse_app_id(matched[2], @description)
      ContrastPayloadParser.parse_vul_id(matched[3], @description)
    else
      false
    end
  end

end
