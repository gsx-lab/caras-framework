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
require_relative '../app_helper'

RSpec.describe AttachedFile do
  let(:site) { create(:site) }
  let(:host) { create(:host, site: site) }
  let(:evidence) { create(:evidence, host: host) }
  let(:png) { create(:attached_file, :png, evidence: evidence) }
  let(:text) { create(:attached_file, :text, evidence: evidence) }
  let(:binary) { create(:attached_file, :binary, evidence: evidence) }
  let(:filemagic) { FileMagic.new(FileMagic::MAGIC_MIME) }

  describe 'validation' do
    subject { png }

    it { is_expected.to be_valid }

    describe 'evidence' do
      it 'should not be nil' do
        png.evidence = nil
        is_expected.not_to be_valid
      end

      it 'should be exist' do
        png.evidence_id = Evidence.maximum(:id) + 1
        is_expected.not_to be_valid
      end
    end

    describe 'filename' do
      it 'should not be nil' do
        png.filename = nil
        is_expected.not_to be_valid
        png.filename = ''
        is_expected.not_to be_valid
      end
    end

    describe 'file' do
      it 'should not be nil' do
        png.file = nil
        is_expected.not_to be_valid
        png.file = ''
        is_expected.not_to be_valid
      end
    end
  end

  describe 'function' do
    describe '#content_type' do
      it 'tells valid content type' do
        expect(png.content_type).to start_with 'image/png'
        expect(text.content_type).to start_with 'text/plain'
        expect(binary.content_type).to start_with 'application/octet-stream'
      end
    end

    describe '#to_html' do
      it 'responds image tag when attached_file is png' do
        content_type = filemagic.buffer(png.file).split('; ')[0]
        encoded64 = Base64.encode64(png.file)
        expected_html = "<img class=\"img-responsive\" src=\"data:#{content_type};base64,#{encoded64}\">"
        expect(png.to_html).to eq expected_html
      end

      it 'responds pre tag with plain text when attached_file is text' do
        inner_text = CGI.escapeHTML(text.file.force_encoding('UTF-8'))
        expected_html = "<pre>#{inner_text}</pre>"
        expect(text.to_html).to eq expected_html
      end

      it 'responds pre tag with base64 encoded text when attached_file is binary' do
        inner_text = CGI.escapeHTML(Base64.encode64(binary.file).force_encoding('UTF-8'))
        expected_html = "<pre>#{inner_text}</pre>"
        expect(binary.to_html).to eq expected_html
      end
    end
  end
end
