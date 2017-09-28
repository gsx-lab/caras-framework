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

RSpec.describe TestCaseCommands do
  let(:site) { FactoryGirl.create(:site) }
  let(:host) { FactoryGirl.create(:host, site: site) }
  let(:port) { FactoryGirl.create(:port, host: host) }
  let(:testcase_name) { 'TestSuites::Default::Path::To::First' }
  let(:testcase) { TestCase.find_by(name: testcase_name) }
  let(:evidence) { FactoryGirl.create(:evidence, port: port, title: testcase.name) }
  let(:banner) { FactoryGirl.create(:banner, port: port, detected_by: testcase.name) }

  describe 'tree' do
    it 'shows test case tree' do
      call_command('testcase tree')
      expect(command_stdout_mono.lines.count).to eq 9
    end
  end

  describe 'info' do
    it 'shows information for all test cases' do
      call_command('testcase info')
      lines = command_stdout_mono.lines.map(&:chomp)
      expect(lines[0]).to eq 'TestSuites::Default::Path::To::First'
      expect(lines[7]).to eq 'TestSuites::Default::Path::To::Second'
      expect(lines[14]).to eq 'TestSuites::Default::Path::To::SecondSibling'
      expect(lines.count).to eq 20
    end

    it 'shows information for specified test case' do
      call_command('testcase info TestSuites::Default::Path::To::Second')
      lines = command_stdout_mono.lines.map(&:chomp)
      expect(lines.count).to eq 6
      expect(lines[0]).to eq 'TestSuites::Default::Path::To::Second'
      expect(lines[1]).to eq ' description  Second'
      expect(lines[2]).to eq ' protocol     SecondProtocol'
      expect(lines[3]).to eq ' requires     TestSuites::Default::Path::To::First'
      expect(lines[4]).to eq ' dangles      tree'
      expect(lines[5]).to eq ' author       SecondAuthor'
    end
  end

  describe 'new' do
    it 'creates new test_suite template' do
      call_command('testcase new new/test/case.rb')
      message = command_stdout_mono.chomp
      file_path = message.match(/in (.+)\z/)[1]
      expect(File).to exist(file_path)
    end

    it 'shows messages' do
      call_command('testcase new new/test/case.rb')
      expect(command_stdout_mono).to start_with('new test case is generated in ')
    end

    describe 'parameter check' do
      subject { command_stdout_mono.lines[0].chomp }

      it {
        call_command('testcase new no/ext')
        is_expected.to eq 'path must end with ".rb".'
      }

      it {
        call_command('testcase new invalid?characters.rb')
        is_expected.to eq 'invalid character.'
      }

      it {
        call_command('testcase new no/basename/.rb')
        is_expected.to eq 'basename must be required.'
      }

      it {
        call_command('testcase new invalid/underscore/_position.rb')
        is_expected.to eq 'underscore must be between alphabets/numbers.'

        call_command('testcase new invalid/underscore_/position.rb')
        is_expected.to eq 'underscore must be between alphabets/numbers.'
      }

      it {
        call_command('testcase new does/not/starts/with/1alphabet.rb')
        is_expected.to eq 'each directory or basename must start with alphabet.'

        call_command('testcase new 1does/not/starts/with/alphabet.rb')
        is_expected.to eq 'each directory or basename must start with alphabet.'
      }

      it {
        call_command('testcase new individual.rb')
        is_expected.to eq 'reserved.'

        call_command('testcase new individual/test/case.rb')
        is_expected.to eq 'reserved.'
      }

      it {
        call_command('testcase new path/to/first.rb')
        is_expected.to eq 'already exists.'
      }
    end
  end

  describe 'run' do
    before :each do
      host
      call_command('site select 1')
    end

    describe 'stop to run' do
      let(:testcase_name) { 'TestSuites::Default::Path::To::Second' }
      subject { command_stdout_mono.lines[-1].chomp }

      it 'stops to run when enter "x" to test case selection' do
        call_command('testcase run', answer: 'x')
        is_expected.to eq 'Which do you want to run? [1 - 3] x'
      end

      it 'stops to run when enter "x" to test target selection' do
        call_command('testcase run', answer: %w[1 x])
        is_expected.to eq 'Which do you want to test? [1] x'
      end

      it 'stops to run when enter "x" to target port selection' do
        call_command("testcase run #{testcase_name}", answer: %w[1 x])
        is_expected.to eq 'Select target port number or 0 to leave it to test case\'s choice. [0 - 65535] x'
      end

      context 'the port has evidences' do
        before :each do
          evidence
        end

        it 'stops to run when enter "x" to evidence deletion' do
          call_command("testcase run #{testcase_name}", answer: %w[1 0 x])
          expect(command_stdout_mono.lines[-2].chomp).to eq "1 test evidences of #{testcase_name} for #{host.ip} would be destroyed."
          is_expected.to eq 'Really want to run? [Y/n] > x'
          expect(Evidence.exists?(evidence.id)).to be true
        end

        it 'runs when answer "Y"' do
          call_command "testcase run #{testcase_name}", answer: %w[1 0 Y]
          is_expected.to eq "#{testcase_name} end"
          expect(Evidence.exists?(evidence.id)).to be false
        end

        it 'also runs when answer "y"' do
          call_command "testcase run #{testcase_name}", answer: %w[1 0 y]
          is_expected.to eq "#{testcase_name} end"
          expect(Evidence.exists?(evidence.id)).to be false
        end
      end

      context 'the port has banners' do
        before :each do
          banner
        end

        it 'stops to run when enter "x" to banners deletion' do
          call_command("testcase run #{testcase_name}", answer: %w[1 0 x])
          expect(command_stdout_mono.lines[-2].chomp).to eq "1 banners of #{testcase_name} for #{host.ip} would be destroyed."
          is_expected.to eq 'Really want to run? [Y/n] > x'
          expect(Banner.exists?(banner.id)).to be true
        end

        it 'runs when answer "Y"' do
          call_command "testcase run #{testcase_name}", answer: %w[1 0 Y]
          is_expected.to eq "#{testcase_name} end"
          expect(Banner.exists?(banner.id)).to be false
        end

        it 'also runs when answer "y"' do
          call_command "testcase run #{testcase_name}", answer: %w[1 0 y]
          is_expected.to eq "#{testcase_name} end"
          expect(Banner.exists?(banner.id)).to be false
        end
      end

      context 'the port has evidences and banners' do
        before :each do
          evidence
          banner
        end

        it 'stops to run when enter "x" to banners deletion' do
          call_command("testcase run #{testcase_name}", answer: %w[1 0 x])
          expect(command_stdout_mono.lines[-2].chomp).to eq "1 test evidences and 1 banners of #{testcase_name} for #{host.ip} would be destroyed."
          is_expected.to eq 'Really want to run? [Y/n] > x'

          expect(Evidence.exists?(evidence.id)).to be true
          expect(Banner.exists?(banner.id)).to be true
        end

        it 'runs when answer "Y"' do
          call_command "testcase run #{testcase_name}", answer: %w[1 0 Y]
          is_expected.to eq "#{testcase_name} end"
          expect(Evidence.exists?(evidence.id)).to be false
          expect(Banner.exists?(banner.id)).to be false
        end

        it 'also runs when answer "y"' do
          call_command "testcase run #{testcase_name}", answer: %w[1 0 y]
          is_expected.to eq "#{testcase_name} end"
          expect(Evidence.exists?(evidence.id)).to be false
          expect(Banner.exists?(banner.id)).to be false
        end
      end
    end

    describe 'run the testcase' do
      let(:file_content) { path_to[:data].join(site.name, host.ip, testcase_name.gsub('::', '_'), 'result').read }

      context 'attack' do
        let(:testcase_name) { 'TestSuites::Default::Path::To::First' }
        it 'runs the test case' do
          call_command("testcase run #{testcase_name}", answer: %w[1 0])
          expect(file_content).to eq "#{testcase_name} is successfully called.\n"
        end
      end

      context 'attack_on_port' do
        let(:testcase_name) { 'TestSuites::Default::Path::To::Second' }
        let(:http) { FactoryGirl.create(:port, :http, host: host) }

        before :each do
          port
          http
        end

        it 'runs the test case for ports' do
          call_command("testcase run #{testcase_name}", answer: %w[1 0])
          expect(file_content.lines.length).to eq 2
          expect(file_content).to match /^#{testcase_name} is successfully called. Port no = #{port.no}$/
          expect(file_content).to match /^#{testcase_name} is successfully called. Port no = #{http.no}$/
        end
      end
    end
  end
end
