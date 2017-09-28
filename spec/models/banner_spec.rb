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

RSpec.describe Banner do
  let(:site) { create(:site) }
  let(:host) { create(:host, site: site) }
  let(:port) { create(:port, host: host) }
  let(:other_port) { create(:port, :http, host: host) }
  let(:banner) { create(:banner, port: port) }
  let(:other_banner) { create(:banner, :other, port: port) }

  describe 'validation' do
    subject { banner }

    it { is_expected.to be_valid }

    describe 'port' do
      it 'should not be nil' do
        banner.port = nil
        is_expected.not_to be_valid
      end
      it 'should be exist' do
        banner.port_id = Port.maximum(:id) + 1
        is_expected.not_to be_valid
      end
    end

    describe 'info' do
      it 'should not be blank' do
        banner.info = nil
        is_expected.not_to be_valid
        banner.info = ''
        is_expected.not_to be_valid
      end

      it 'should unique in port' do
        banner.info = other_banner.info
        is_expected.not_to be_valid
      end

      it 'is allowed to be same in different port' do
        banner.info = other_banner.info
        banner.port = other_port
        is_expected.to be_valid
      end
    end

    describe 'detected_by' do
      it 'should not be blank' do
        banner.detected_by = nil
        is_expected.not_to be_valid

        banner.detected_by = ''
        is_expected.not_to be_valid
      end
    end
  end
end
