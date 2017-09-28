# Copyright 2017 Global Security Experts Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class AttachedFile < ApplicationRecord
  belongs_to :evidence, required: true

  validates :filename, presence: true
  validates :file, presence: true

  def content_type
    fm = FileMagic.new(FileMagic::MAGIC_MIME)
    fm.buffer(file)
  end

  def to_html
    return nil if file.nil?
    mt = content_type
    case mt
    when /^image/
      "<img class=\"img-responsive\" src=\"data:#{mt.split('; ')[0]};base64,#{encode64}\">"
    when /^text/
      "<pre>#{CGI.escapeHTML(file.force_encoding('UTF-8'))}</pre>"
    else
      "<pre>#{CGI.escapeHTML(encode64.force_encoding('UTF-8'))}</pre>"
    end
  end

  def encode64
    Base64.encode64(file)
  end
end
