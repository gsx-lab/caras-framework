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
require_relative '../command_helper'

RSpec.describe HostnameCommands do
  let(:site) { create(:site) }
  let(:host) { create(:host, site: site) }
  let(:hostname) { create(:hostname, host: host) }

  describe 'list' do
    context 'before select site' do
      it 'warns to select site first' do
        call_command('hostname list')
        expect(command_stdout_mono.chomp).to eq('Select site first')
      end
    end

    context 'after select site' do
      before :each do
        host
        call_command('site select 1')
      end

      context 'with no hostnames' do
        it 'shows no hostnames' do
          call_command('hostname list')
          expect(command_stdout.lines.length).to eq 4
          expect(command_stdout.lines[2].split(' ').length).to eq 1
        end
      end

      context 'with a hostname' do
        before :each do
          hostname
        end

        it 'shows a hostname' do
          call_command('hostname list')
          expect(command_stdout.lines.length).to eq 4
          result = command_stdout.lines[2].split(' ')[1]
          expect(result).to eq hostname.name
        end
      end
    end
  end

  describe 'add' do
    context 'before select site' do
      it 'warns to select site first' do
        call_command('hostname add')
        expect(command_stdout_mono.chomp).to eq('Select site first')
      end
    end

    context 'after select site' do
      before :each do
        host
        call_command('site select 1')
      end

      context 'specify malformed arguments' do
        it 'shows error when no params' do
          call_command('hostname add')
          expect(command_stdout_mono.chomp).to eq('Target ip address and hostname are required')
        end

        it 'shows error when ip address only' do
          call_command('hostname add 192.168.1.1')
          expect(command_stdout_mono.chomp).to eq('Target ip address and hostname are required')
        end

        it 'shows error when not existing ip address' do
          call_command('hostname add 192.168.1.1 hostname')
          expect(command_stdout_mono.chomp).to eq('Target ip address 192.168.1.1 does not exist.')
        end
      end

      context 'specify existing hostname' do
        before :each do
          hostname
        end

        it 'shows error' do
          call_command("hostname add #{host.ip} #{hostname.name}")
          expect(command_stdout_mono.chomp).to eq('Name has already been taken')
        end
      end

      context 'normal operation' do
        before :each do
          hostname
        end

        it 'creates successfully' do
          call_command("hostname add #{host.ip} new.#{hostname.name}")
          expect(command_stdout_mono.chomp).to eq("Added new.#{hostname.name} to #{host.ip}")
        end

        it 'creates new hostname record' do
          expect {
            call_command("hostname add #{host.ip} new.#{hostname.name}")
          }.to change(Hostname, :count).by(1)
        end

        it 'creates new hostname as specified hostname' do
          call_command("hostname add #{host.ip} new.#{hostname.name}")
          host.reload
          expect(host.hostnames.where(name: "new.#{hostname.name}")).to exist
        end
      end
    end
  end

  describe 'delete' do
    context 'before select site' do
      it 'warns to select site first' do
        call_command('hostname list')
        expect(command_stdout_mono.chomp).to eq('Select site first')
      end
    end

    context 'after select site' do
      before :each do
        host
        hostname
        call_command('site select 1')
      end

      context 'specify malformed arguments' do
        it 'shows error when no params' do
          call_command('hostname delete')
          expect(command_stdout_mono.chomp).to eq('Target ip address and hostname are required')
        end

        it 'shows error when ip address only' do
          call_command('hostname delete 192.168.1.1')
          expect(command_stdout_mono.chomp).to eq('Target ip address and hostname are required')
        end

        it 'shows error when not existing ip address' do
          call_command('hostname delete 192.168.1.1 hostname')
          expect(command_stdout_mono.chomp).to eq('Target ip address 192.168.1.1 does not exist.')
        end

        it 'shows error when not existing hostname' do
          call_command("hostname delete #{host.ip} #{hostname.name}.not.exists")
          expect(command_stdout_mono.chomp).to eq("#{hostname.name}.not.exists of #{host.ip} does not exist.")
        end
      end

      context 'normal operation' do
        it 'deletes successfully' do
          call_command("hostname delete #{host.ip} #{hostname.name}")
          expect(command_stdout_mono.chomp).to eq("#{hostname.name} of #{host.ip} is deleted.")
        end

        it 'deletes hostname record' do
          expect {
            call_command("hostname delete #{host.ip} #{hostname.name}")
          }.to change(Hostname, :count).by(-1)
        end

        it 'deletes hostname specified record' do
          call_command("hostname delete #{host.ip} #{hostname.name}")
          expect(host.hostnames.where(name: hostname.name)).not_to exist
        end
      end
    end
  end
end
