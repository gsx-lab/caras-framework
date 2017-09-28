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

RSpec.describe Port do
  let(:site) { create(:site) }
  let(:host) { create(:host, site: site) }
  let(:port) { create(:port, host: host) }
  let(:http) { create(:port, :http, host: host) }
  let(:smtp) { create(:port, :smtp, host: host) }
  let(:open) { create(:port, :open, host: host) }
  let(:closed) { create(:port, :closed, host: host) }
  let(:plain) { create(:port, :plain, host: host) }
  let(:ssl) { create(:port, :ssl, host: host) }
  let(:udp) { create(:port, :udp, host: host) }
  let(:tcp) { create(:port, :tcp, host: host) }

  it 'validates factories successfully' do
    expect(port).to be_valid
    expect(http).to be_valid
    expect(smtp).to be_valid
    expect(open).to be_valid
    expect(closed).to be_valid
    expect(plain).to be_valid
    expect(ssl).to be_valid
    expect(udp).to be_valid
    expect(tcp).to be_valid
  end

  describe 'references' do
    it 'is not valid without host' do
      port.host = nil
      expect(port).not_to be_valid
    end

    it 'can refer site' do
      expect(port.site).to eq site
    end

    describe '#destroy' do
      context 'has evidence' do
        before :each do
          @evidence = create(:evidence, port: port)
        end

        it 'also destroys evidences' do
          expect { port.destroy }.to change(Evidence, :count).by(-1)
        end

        context 'has vulnerability' do
          before :each do
            @vulnerability = create(:vulnerability, site: site)
            @other_evidence = create(:evidence, host: host, vulnerability: @vulnerability)
            @evidence.vulnerability = @vulnerability
            @evidence.save
          end

          it 'does not destroy vulnerability which is referred by other evidences' do
            expect { port.destroy }.to change(Vulnerability, :count).by(0)
          end

          it 'destroys vulnerability which is not referred by other evidences' do
            @other_evidence.port = port
            @other_evidence.save
            expect { port.destroy }.to change(Vulnerability, :count).by(-1)
          end
        end
      end

      context 'has banners' do
        before :each do
          @banner = create(:banner, port: port)
        end
        it 'also destroys banners' do
          expect { port.destroy }.to change(Banner, :count).by(-1)
        end
      end
    end
  end

  describe 'validation' do
    subject { port }

    context 'host' do
      it 'is required' do
        port.host = nil
        is_expected.not_to be_valid
      end

      it 'should be exist' do
        port.host_id = Host.maximum(:id) + 1
        is_expected.not_to be_valid
      end
    end

    context 'proto' do
      it 'is required' do
        port.proto = nil
        is_expected.not_to be_valid
      end

      it 'allowed to be "tcp" or "udp"' do
        port.proto = 'tcp'
        is_expected.to be_valid
        port.proto = :tcp
        is_expected.to be_valid
        port.proto = 'udp'
        is_expected.to be_valid
        port.proto = :udp
        is_expected.to be_valid
        port.proto = :other
        is_expected.not_to be_valid
      end
    end


    context 'no' do
      it 'is required' do
        port.no = nil
        is_expected.not_to be_valid
      end

      it 'should be unique in host and proto' do
        port.save
        http.save
        port.no = 80
        is_expected.not_to be_valid
      end

      it 'should be in 1-65535' do
        port.no = -1
        is_expected.not_to be_valid
        port.no = 0
        is_expected.not_to be_valid
        port.no = 1
        is_expected.to be_valid
        port.no = 65535
        is_expected.to be_valid
        port.no = 65536
        is_expected.not_to be_valid
        port.no = 65537
        is_expected.not_to be_valid
      end
    end
  end

  describe 'scope' do
    before :each do
      port
      http
      smtp
      open
      closed
      plain
      ssl
      udp
      tcp
    end

    describe 'ssl' do
      it 'extracts records which ssl is true' do
        expect(Port.ssl).to match_array [ssl]
      end
    end

    describe 'plain' do
      it 'extracts records which plain is true' do
        expect(Port.plain).to match_array [plain]
      end
    end

    describe 'service' do
      it 'extracts records matched service name to specified' do
        expect(Port.service('http')).to match_array [http]
        expect(Port.service('smtp')).to match_array [smtp]
      end
    end

    describe 'nmap_service' do
      it 'extracts records matched nmap_service name to specified' do
        expect(Port.nmap_service('http nmap')).to match_array [http]
        expect(Port.nmap_service('smtp nmap')).to match_array [smtp]
      end
    end

    describe 'open_ports' do
      it 'extracts records open' do
        expect(Port.open_ports).to match_array([open])
      end
    end
  end
end
