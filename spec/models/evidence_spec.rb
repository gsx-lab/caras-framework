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
  let(:host) { create(:host, site: site) }
  let(:port) { create(:port, host: host) }

  let(:evidence) { create(:evidence, host: host, port: port) }
  let(:other_evidence) { create(:evidence, port: port) }

  let(:vulnerability) { create(:vulnerability, site: site) }

  describe 'validation' do
    subject { evidence }

    it { is_expected.to be_valid }

    describe 'title' do
      it 'should not be blank' do
        evidence.title = nil
        is_expected.not_to be_valid
        evidence.title = ''
        is_expected.not_to be_valid
      end
    end

    describe 'host or port' do
      it 'should not be blank' do
        evidence.port = nil
        evidence.host = nil
        is_expected.not_to be_valid

        evidence.port = port
        evidence.host = nil
        is_expected.to be_valid

        evidence.port = nil
        evidence.host = host
        is_expected.to be_valid
      end
    end

    describe 'host' do
      it 'should be exist' do
        evidence.port = nil
        evidence.host_id = Host.maximum(:id) + 1
        is_expected.not_to be_valid
      end
    end

    describe 'port' do
      it 'should be exist' do
        evidence.host = nil
        evidence.port_id = Port.maximum(:id) + 1
        is_expected.not_to be_valid
      end
    end

  end

  describe 'function' do
    describe '#set_default_keys' do
      it 'sets site and host keys when port is set' do
        evidence.site = nil
        evidence.host = nil
        evidence.port = port
        evidence.valid?
        expect(evidence.host).to eq host
        expect(evidence.site).to eq site
      end

      it 'sets site keys when host is set' do
        evidence.site = nil
        evidence.host = host
        evidence.valid?
        expect(evidence.site).to eq site
      end

      it 'corrects the site_id based on host' do
        evidence.site_id = Site.maximum(:id) + 1
        evidence.valid?
        expect(evidence.site).to eq site
      end

      it 'corrects the site_id based on port' do
        evidence.site_id = Site.maximum(:id) + 1
        evidence.host = nil
        evidence.valid?
        expect(evidence.site).to eq site

      end
    end

    describe '#destroy_orphan_vulnerabilities' do
      before :each do
        evidence.vulnerability = vulnerability
        evidence.save
      end
      context 'update evidence' do
        context 'the vulnerability would be orphan' do
          it 'destroys the vulnerability' do
            expect(Vulnerability.where(id: vulnerability.id)).to exist

            evidence.vulnerability = nil
            evidence.save
            expect(Vulnerability.where(id: vulnerability.id)).not_to exist
          end
        end

        context 'the vulnerability would not be orphan' do
          it 'does not destroy the vulnerability' do
            expect(Vulnerability.where(id: vulnerability.id)).to exist

            other_evidence.vulnerability = vulnerability
            other_evidence.save
            evidence.vulnerability = nil
            evidence.save
            expect(Vulnerability.where(id: vulnerability.id)).to exist
          end
        end
      end

      context 'destroy evidence' do
        context 'the vulnerability would be orphan' do
          it 'destroys the vulnerability' do
            expect(Vulnerability.where(id: vulnerability.id)).to exist

            evidence.destroy
            expect(Vulnerability.where(id: vulnerability.id)).not_to exist
          end
        end

        context 'the vulnerability would not be orphan' do
          it 'does not destroy the vulnerability' do
            expect(Vulnerability.where(id: vulnerability.id)).to exist

            other_evidence.vulnerability = vulnerability
            other_evidence.save
            evidence.destroy
            expect(Vulnerability.where(id: vulnerability.id)).to exist
          end
        end
      end
    end
  end
end
