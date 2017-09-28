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

RSpec.describe TesterCommands do
  let(:site) { FactoryGirl.create(:site) }
  let(:host) { FactoryGirl.create(:host, site: site) }
  let(:port) { FactoryGirl.create(:port, host: host) }

  describe 'attack' do
    describe 'fails to run' do
      context 'site is not selected' do
        it 'shows error' do
          call_command 'attack'
          expect(command_stdout_mono.chomp).to eq 'Select site first'
        end
      end

      context 'host is not registered' do
        before :each do
          site
          call_command 'site select 1'
        end

        it 'shows error' do
          call_command 'attack'
          expect(command_stdout_mono.chomp).to eq 'Add target first'
        end
      end

      context 'running any other test' do
        before :each do
          host
          call_command 'site select 1'
          call_command 'testsuite select slow'
          call_command 'attack'
        end

        after :each do
          call_command 'stop', answer: 'Y', wait_for: 'Done all tests'
        end

        it 'shows error' do
          sleep 0.1
          call_command 'attack'
          expect(command_stdout_mono.chomp).to eq 'Some tests are running. View status for description.'
        end
      end
    end

    describe 'runs successfully' do
      before :each do
        port
        call_command 'site select 1'
        call_command 'testsuite select slow'
      end

      let(:dirs) do
        {
          parent: 'TestSuites_Slow_Parent',
          first: 'TestSuites_Slow_FirstChild',
          second: 'TestSuites_Slow_SecondChild'
        }
      end

      let(:result_dir) { path_to[:data].join(site.name, host.ip) }
      let(:parent_result) { result_dir.join(dirs[:parent], 'result') }
      let(:first_result) { result_dir.join(dirs[:first], 'result') }
      let(:second_result) { result_dir.join(dirs[:second], 'result') }

      it 'runs test suite as tree shaped' do
        call_command 'attack', wait_for: 'Done all tests'
        expect(File).to exist parent_result
        expect(File).to exist first_result
        expect(File).to exist second_result

        expect(parent_result.stat.ctime).to be < first_result.stat.ctime
        expect(parent_result.stat.ctime).to be < second_result.stat.ctime
      end

      it 'updates attack_finished column' do
        call_command 'attack', wait_for: 'Done all tests'
        site.reload
        expect(site.attack_finished).not_to be_nil
      end
    end

    describe 'confirmation' do
      before :each do
        host.test_status = :tested
        host.save
        call_command 'site select 1'
      end

      it 'confirms to rerun and runs when the answer is "Y"' do
        call_command 'attack', answer: 'Y', wait_for: 'Done all tests'
        expect(command_stdout_mono).to match /Done tests for #{host.ip}/
      end

      it 'runs when the answer is "y"' do
        call_command 'attack', answer: 'y', wait_for: 'Done all tests'
        expect(command_stdout_mono).to match /Done tests for #{host.ip}/
      end

      it 'runs when the answer is "n"' do
        call_command 'attack', answer: 'n', wait_for: 'Done all tests'
        expect(command_stdout_mono).not_to match /Done tests for #{host.ip}/
      end
    end

    context 'against many targets' do
      before :each do
        site
        call_command 'site select 1'
        call_command 'toggle'
      end

      describe 'attack on host' do
        before :each do
          (env_config['test_case_thread_limit'] + 1).times do |no|
            FactoryGirl.create(:host, site: site, ip: "127.0.0.#{no}")
          end
          call_command 'testsuite select slow_test_for_host'
        end

        it 'waits for threads limitation' do
          call_command 'attack', wait_for: 'Done all tests'
          waiting_logs = command_stdout_mono.lines.select { |l| l.include? ' waiting...(waiting:' }
          expect(waiting_logs.length).to eq 1
        end
      end

      describe 'attack on port' do
        before :each do
          (env_config['test_case_thread_limit'] + 1).times do |no|
            FactoryGirl.create(:port, host: host, no: no + 1)
          end
          call_command 'testsuite select slow_test_for_port'
        end

        it 'waits for threads limitation' do
          call_command 'attack', wait_for: 'Done all tests'
          waiting_logs = command_stdout_mono.lines.select { |l| l.include? ' waiting...(waiting:' }
          expect(waiting_logs.length).to eq 1
        end
      end
    end
  end

  describe 'status' do
    before :each do
      port
      call_command 'site select 1'
      call_command 'testsuite select slow'
    end

    after :each do
      call_command 'stop', answer: 'Y', wait_for: 'Done all tests'
    end

    it 'shows running status' do
      call_command 'attack'
      loop do
        sleep 0.1
        call_command 'status'
        if command_stdout_mono.include?('run TestSuites::Slow::FirstChild') &&
           command_stdout_mono.include?('run TestSuites::Slow::SecondChild')
          break
        end
      end

      lines = command_stdout_mono.lines.map(&:chomp)
      expect(lines[0]).to eq "Tester:#{host.ip}@#{site.name} => running: [ 0 > 2 > 1 ]"
      expect(lines[2]).to eq ' `--fin TestSuites::Slow::Parent'
      expect(lines[3]).to eq '    |--run TestSuites::Slow::FirstChild'
      expect(lines[4]).to eq '    `--run TestSuites::Slow::SecondChild'

      queued = command_stdout_mono.match(/Queued  testers : (.+)/)[1].to_i
      running = command_stdout_mono.match(/Running testers : (.+)\/.+/)[1].to_i

      expect(queued).not_to eq 0
      expect(running).not_to eq 0
    end
  end

  describe 'stop' do
    let(:lines) { command_stdout_mono.lines.map(&:chomp) }

    before :each do
      port
      call_command 'site select 1'
      call_command 'testsuite select slow'
      call_command 'attack'
      sleep 0.1
    end

    it 'stops running test cases when the answer is "Y"' do
      call_command 'stop', answer: 'Y', wait_for: 'Done all tests'

      call_command 'status'

      expect(lines[0]).to eq "Tester:#{host.ip}@#{site.name} => running: [ 2 > 0 > 1 ]"
      expect(lines[2]).to eq ' `--fin TestSuites::Slow::Parent'
      expect(lines[3]).to eq '    |--TestSuites::Slow::FirstChild'
      expect(lines[4]).to eq '    `--TestSuites::Slow::SecondChild'

      queued = command_stdout_mono.match(/Queued  testers : (.+)/)[1].to_i
      running = command_stdout_mono.match(/Running testers : (.+)\/.+/)[1].to_i
      waiting = command_stdout_mono.match(/Waiting testers : (.+)/)[1].to_i

      expect(queued).to eq 0
      expect(running).to eq 0
      expect(waiting).to eq 0
    end

    it 'also stops when answer "y"' do
      call_command 'stop', answer: 'y', wait_for: 'Done all tests'
      call_command 'status'

      expect(lines[0]).to eq "Tester:#{host.ip}@#{site.name} => running: [ 2 > 0 > 1 ]"
      expect(lines[2]).to eq ' `--fin TestSuites::Slow::Parent'
      expect(lines[3]).to eq '    |--TestSuites::Slow::FirstChild'
      expect(lines[4]).to eq '    `--TestSuites::Slow::SecondChild'

      queued = command_stdout_mono.match(/Queued  testers : (.+)/)[1].to_i
      running = command_stdout_mono.match(/Running testers : (.+)\/.+/)[1].to_i
      waiting = command_stdout_mono.match(/Waiting testers : (.+)/)[1].to_i

      expect(queued).to eq 0
      expect(running).to eq 0
      expect(waiting).to eq 0
    end

    it 'does not stop when the answer is "n"' do
      call_command 'stop', answer: 'n', wait_for: 'Done all tests'
      call_command 'status'

      expect(lines[0]).to eq "Tester:#{host.ip}@#{site.name} => running: [ 0 > 0 > 3 ]"
      expect(lines[2]).to eq ' `--fin TestSuites::Slow::Parent'
      expect(lines[3]).to eq '    |--fin TestSuites::Slow::FirstChild'
      expect(lines[4]).to eq '    `--fin TestSuites::Slow::SecondChild'

      queued = command_stdout_mono.match(/Queued  testers : (.+)/)[1].to_i
      running = command_stdout_mono.match(/Running testers : (.+)\/.+/)[1].to_i
      waiting = command_stdout_mono.match(/Waiting testers : (.+)/)[1].to_i

      expect(queued).to eq 0
      expect(running).to eq 0
      expect(waiting).to eq 0
    end
  end
end
