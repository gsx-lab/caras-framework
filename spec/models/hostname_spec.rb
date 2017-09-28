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

RSpec.describe Hostname do
  let(:site) { create(:site) }
  let(:host) { create(:host, site: site) }
  let(:other_host) { create(:host, :other, site: site) }
  let(:hostname) { create(:hostname, host: host) }
  let(:other_hostname) { create(:hostname, :other, host: host) }

  describe 'validation' do
    subject { hostname }
    it { is_expected.to be_valid }
    it { expect(other_hostname).to be_valid }

    describe 'host_id' do
      it 'should not be nil' do
        hostname.host_id = nil
        is_expected.not_to be_valid
      end

      it 'should exist' do
        hostname.host_id = Host.maximum(:id) + 1
        is_expected.not_to be_valid
      end
    end

    describe 'name' do
      it 'should not be blank' do
        hostname.name = nil
        is_expected.not_to be_valid
        hostname.name = ''
        is_expected.not_to be_valid
        hostname.name = 'test.name'
        is_expected.to be_valid
      end

      it 'should be unique in host' do
        hostname.name = other_hostname.name
        is_expected.not_to be_valid
      end

      it 'is allowed to give same name to different hosts' do
        hostname.name = other_hostname.name
        hostname.host = other_host
        is_expected.to be_valid
      end
    end
  end
end
