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

RSpec.describe Site do
  let(:site) { create(:site) }
  let(:host) { create(:host, site: site) }
  let(:evidence) { create(:evidence, site: site, host: host) }
  let(:vulnerability) { create(:vulnerability, site: site) }

  describe 'validation' do
    subject { site }
    it { is_expected.to be_valid }

    describe 'name' do
      it 'should have allowed characters only' do
        site.name = 'site-with#special$char'
        is_expected.to be_valid

        site.name = 'site with special char '
        is_expected.not_to be_valid

        site.name = 'site-with_special-char_\''
        is_expected.not_to be_valid

        site.name = 'site-with_special-char_"'
        is_expected.not_to be_valid

        site.name = 'site-with_special-char_('
        is_expected.not_to be_valid
      end
    end
  end

  describe 'function' do
    it { expect(site.dir(path_to)).to eq(path_to[:data].join(site.name)) }

    context 'it have a host' do
      before :each do
        host.save
      end

      it { expect(host).to be_valid }
      it { expect { site.destroy }.to change(Host, :count).by(-1) }

      context 'and the host have a evidence' do
        before :each do
          evidence.save
        end

        it { expect(evidence).to be_valid }
        it { expect { site.destroy }.to change(Evidence, :count).by(-1) }

        context 'and the vulnerability is registered by the evidence' do
          before :each do
            evidence.vulnerability = vulnerability
            evidence.save
          end

          it { expect(vulnerability).to be_valid }
          it { expect { site.destroy }.to change(Vulnerability, :count).by(-1) }
        end
      end
    end
  end
end
