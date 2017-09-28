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

RSpec.describe TargetCommands do
  let(:site) { FactoryGirl.create(:site) }
  let(:host) { FactoryGirl.create(:host, site: site) }

  describe 'list' do
    context 'before select site' do
      it 'shows error' do
        call_command('target list')
        expect(command_stdout_mono.chomp).to eq 'Select site first'
      end
    end

    context 'after select site' do
      before :each do
        host
        call_command('site select 1')
      end

      it 'shows list of hosts' do
        call_command('target list')
        lines = command_stdout_mono.lines.map(&:chomp)
        expect(lines[0].strip).to eq 'List of Host'
        addr = lines[2].strip.split(' ')[1]
        expect(addr).to eq host.ip
      end
    end
  end

  describe 'add' do
    context 'before select site' do
      it 'shows error' do
        call_command('target add 127.0.0.1')
        expect(command_stdout_mono.chomp).to eq 'Select site first'
      end
    end

    context 'after select site' do
      before :each do
        site
        call_command('site select 1')
      end

      context 'malformed arguments' do
        it 'shows error when no ip address' do
          call_command('target add')
          expect(command_stdout_mono.chomp).to eq 'one parameter is required'
        end

        it 'shows error when malformed ip address' do
          call_command('target add malformed')
          expect(command_stdout_mono.chomp).to eq 'Ip is invalid'
        end
      end

      context 'with correct argument' do
        it 'shows success message' do
          call_command('target add 127.0.0.1')
          expect(command_stdout_mono.chomp).to eq 'Added ip address : 127.0.0.1'
        end

        it 'creates new record' do
          expect { call_command('target add 127.0.0.1') }.to change(Host, :count).by(1)
        end
      end
    end
  end


  describe 'delete' do
    before :each do
      host
      call_command('site select 1')
    end

    context 'specified by number' do
      it 'inquire about to delete' do
        call_command('target delete 1', answer: 'n')
        expect(command_stdout_mono.lines[0].chomp).to eq "Really want to delete target #{host.ip}? [Y/n] > n"
        expect(command_stdout_mono.lines[1].chomp).to eq 'Canceled to delete the target'
      end

      context 'when specified invalid number' do
        let(:invalid_number) { site.hosts.count + 1 }

        it 'does not delete' do
          expect { call_command("target delete #{invalid_number}", answer: 'y') }.to change(Host, :count).by(0)
        end

        it 'shows error message when specified invalid number' do
          call_command("target delete #{invalid_number}", answer: 'y')
          expect(command_stdout_mono.chomp).to eq "#{invalid_number} is not valid number nor in the Hosts."
        end
      end

      context 'when it is tested' do
        before :each do
          host.test_status = :tested
          host.save
        end

        it 'shows confirmation dialog' do
          call_command('target delete 1', answer: 'Y')
          lines = command_stdout_mono.lines.map(&:chomp)

          expect(lines[0]).to eq 'Test result would be deleted.'
          expect(lines[1]).to eq "Really want to delete target #{host.ip}? [Y/n] > Y"
          expect(lines[2]).to eq "Deleted target #{host.ip} successfully"
        end

        it 'does not delete host when answer n' do
          expect { call_command('target delete 1', answer: 'n') }.to change(Host, :count).by(0)
        end

        it 'deletes host when answer "Y"' do
          expect { call_command('target delete 1', answer: 'Y') }.to change(Host, :count).by(-1)
        end

        it 'also deletes host when answer "y"' do
          expect { call_command('target delete 1', answer: 'y') }.to change(Host, :count).by(-1)
        end
      end
    end

    context 'specified by ip' do
      it 'inquire about to delete' do
        call_command("target delete #{host.ip}", answer: 'n')
        expect(command_stdout_mono.lines[0].chomp).to eq "Really want to delete target #{host.ip}? [Y/n] > n"
        expect(command_stdout_mono.lines[1].chomp).to eq 'Canceled to delete the target'
      end

      context 'when specified invalid ip' do
        let(:invalid_ip) { site.hosts.first.ip + 'x' }

        it 'does not delete' do
          expect { call_command("target delete #{invalid_ip}", answer: 'y') }.to change(Host, :count).by(0)
        end

        it 'shows error message when specified invalid number' do
          call_command("target delete #{invalid_ip}", answer: 'y')
          expect(command_stdout_mono.chomp).to eq "#{invalid_ip} is not valid number nor in the Hosts."
        end
      end

      context 'when it is tested' do
        before :each do
          host.test_status = :tested
          host.save
        end

        it 'shows confirmation dialog' do
          call_command("target delete #{host.ip}", answer: 'Y')
          lines = command_stdout_mono.lines.map(&:chomp)

          expect(lines[0]).to eq 'Test result would be deleted.'
          expect(lines[1]).to eq "Really want to delete target #{host.ip}? [Y/n] > Y"
          expect(lines[2]).to eq "Deleted target #{host.ip} successfully"
        end

        it 'does not delete host when answer n' do
          expect { call_command("target delete #{host.ip}", answer: 'n') }.to change(Host, :count).by(0)
        end

        it 'deletes host when answer "Y"' do
          expect { call_command("target delete #{host.ip}", answer: 'Y') }.to change(Host, :count).by(-1)
        end

        it 'also deletes host when answer "y"' do
          expect { call_command("target delete #{host.ip}", answer: 'y') }.to change(Host, :count).by(-1)
        end
      end
    end
  end
end
