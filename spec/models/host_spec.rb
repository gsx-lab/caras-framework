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

RSpec.describe Host do
  let(:site) { create(:site) }
  let(:other_site) { create(:site, :other) }
  let(:host) { create(:host, site: site) }
  let(:other_host) { create(:host, :other, site: site) }
  let(:port) { create(:port, host: host) }
  let(:udp) { create(:port, :udp, host: host) }
  let(:tcp) { create(:port, :tcp, host: host) }

  let(:tcp80) { create(:port, host: host, proto: :tcp, no: 80) }
  let(:tcp443) { create(:port, host: host, proto: :tcp, no: 443) }
  let(:udp53) { create(:port, host: host, proto: :udp, no: 53) }
  let(:udp123) { create(:port, host: host, proto: :udp, no: 123) }

  let(:e_host) { create(:evidence, host: host) }
  let(:e_tcp80) { create(:evidence, port: tcp80) }
  let(:e_tcp443) { create(:evidence, port: tcp443) }
  let(:e_udp53) { create(:evidence, port: udp53) }
  let(:e_udp123) { create(:evidence, port: udp123) }

  describe 'validation' do
    subject { host }

    it { is_expected.to be_valid }

    describe 'ip' do
      it 'should not be blank' do
        host.ip = nil
        is_expected.not_to be_valid
        host.ip = ''
        is_expected.not_to be_valid
      end

      it 'should be unique in site' do
        host.ip = other_host.ip
        is_expected.not_to be_valid
      end

      it 'is allowed to register same ip to different site' do
        host.ip = other_host.ip
        host.site = other_site
        is_expected.to be_valid
      end
    end

    describe 'site' do
      it 'should not be nil' do
        host.site = nil
        is_expected.not_to be_valid
      end

      it 'should exist' do
        host.site_id = Site.maximum(:id) + 1
        is_expected.not_to be_valid
      end
    end
  end

  describe 'function' do
    context 'about port' do
      before :each do
        port
        udp
        tcp
      end

      describe '#tcp' do
        it 'extracts only tcp ports' do
          expect(host.tcp).to match_array [port, tcp]
        end
      end

      describe '#udp' do
        it 'extracts only udp ports' do
          expect(host.udp).to match_array [udp]
        end
      end
    end

    describe '#evidences_ordered' do
      before :each do
        e_udp123
        e_udp53
        e_tcp443
        e_tcp80
        e_host
      end

      it 'extracts all evidences for the host' do
        expect(host.evidences_ordered).to match_array host.evidences
      end

      it 'should well ordered' do
        expect(host.evidences_ordered).to match [e_host, e_tcp80, e_tcp443, e_udp53, e_udp123]
      end
    end
  end
end
