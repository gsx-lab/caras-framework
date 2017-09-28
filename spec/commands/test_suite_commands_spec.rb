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

RSpec.describe TestSuiteCommands do
  describe 'information disclosure' do
    let(:lines) { command_stdout_mono.lines.map(&:chomp).map { |l| l.split('|').map(&:strip) } }
    describe 'current' do
      it 'shows current test_suite information' do
        call_command 'testsuite current'
        expect(lines.length).to eq 5
        expect(lines[3][3]).to eq 'default'
      end
    end

    describe 'list' do
      it 'shows all test_suite information' do
        call_command 'testsuite list'
        expect(lines.length).to eq 11
        expect(lines[3][3]).to eq '123starts_with_number'
        expect(lines[4][3]).to eq 'default'
        expect(lines[5][3]).to eq 'malformed'
        expect(lines[6][3]).to eq 'malformed-123%test@suite'
        expect(lines[7][3]).to eq 'slow'
        expect(lines[8][3]).to eq 'slow_test_for_host'
        expect(lines[9][3]).to eq 'slow_test_for_port'
      end
    end
  end

  describe 'reload' do
    it 'reloads test suite' do
      expect(Object.const_defined?('TestSuites::Default::NewTest')).to be false

      call_command('testcase new new_test.rb')
      expect(Object.const_defined?('TestSuites::Default::NewTest')).to be false

      call_command('testsuite reload')
      expect(Object.const_defined?('TestSuites::Default::NewTest')).to be true

      path_to[:current_test_suite].join('new_test.rb').unlink

      call_command('testsuite reload')
      expect(Object.const_defined?('TestSuites::Default::NewTest')).to be false
    end
  end

  describe 'select' do
    context 'specified by number' do
      it 'changes current test suite' do
        call_command 'testsuite list'
        number = command_stdout_mono.lines[3..-1].map { |l| l.split('|').map(&:strip) }.find { |l| l[3] == 'malformed' }[2].to_i

        expect(Object.const_defined?('TestSuites::Default')).to be true
        expect(Object.const_defined?('TestSuites::Malformed')).to be false

        call_command "testsuite select #{number}"

        expect(Object.const_defined?('TestSuites::Default')).to be false
        expect(Object.const_defined?('TestSuites::Malformed')).to be true
      end

      it 'does not change test suite when number is invalid' do
        expect(Object.const_defined?('TestSuites::Default')).to be true

        call_command 'testsuite select -1'

        expect(command_stdout_mono.chomp).to eq '-1 is not valid number nor in the TestSuites.'

        expect(Object.const_defined?('TestSuites::Default')).to be true
      end
    end

    context 'specified by name' do
      it 'changes test suite when the name exists' do
        expect(Object.const_defined?('TestSuites::Default')).to be true
        expect(Object.const_defined?('TestSuites::Slow')).to be false

        call_command 'testsuite select slow'

        expect(Object.const_defined?('TestSuites::Default')).to be false
        expect(Object.const_defined?('TestSuites::Slow')).to be true
      end

      it 'does not change test suite when the name does not exist' do
        expect(Object.const_defined?('TestSuites::Default')).to be true

        call_command 'testsuite select not-existing-name'
        expect(command_stdout_mono.chomp).to eq 'not-existing-name is not valid number nor in the TestSuites.'
        expect(Object.const_defined?('TestSuites::Default')).to be true
      end
    end

    it 'does not change test suite if the suite has invalid name' do
      expect(Object.const_defined?('TestSuites::Default')).to be true

      call_command 'testsuite select 123starts_with_number'
      expect(Object.const_get('TestSuites').constants).to match_array([:Default])

      call_command 'testsuite current'
      expect(command_stdout_mono.lines[3].split('|').map(&:strip)[3]).to eq 'default'
    end
  end


  describe 'pull' do
    before :each do
      allow(Git).to receive(:open).and_return(Git::Base.new)
      allow_any_instance_of(Git::Base).to receive(:pull) { |_, r, c| "pulling #{r} #{c}" }
      allow_any_instance_of(Git::Base).to receive(:remote).and_return('remote')
      allow_any_instance_of(Git::Base).to receive(:current_branch).and_return('branch')
    end

    it 'pulls remote' do
      call_command('testsuite pull')
      expect(command_stdout_mono.chomp).to eq 'pulling remote branch'
    end
  end
end