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

RSpec.describe TestCase do
  describe 'test to load TestCases' do
    before :each do
      @test_suite = TestSuite.new(path_to)
      @test_suite.load
    end

    after :each do
      @test_suite.unload
      allow(STDOUT).to receive(:puts) do |val|
        val.to_s + "\n"
      end
    end

    it 'loads and unloads test suite' do
      expect(@test_suite.root).is_a? TestCase
      expect(@test_suite.individual).is_a? TestCase
      expect(@test_suite.orphan).is_a? TestCase
      expect(Object.const_defined?('TestSuites::Default::Path::To::First')).to be true
      expect(Object.const_defined?('TestSuites::Default::Path::To::Second')).to be true
      expect(Object.const_defined?('TestSuites::Default::Path::To::SecondSibling')).to be true

      @test_suite.unload
      expect(Object.const_defined?('TestSuites::Default::Path::To::First')).to be false
      expect(Object.const_defined?('TestSuites::Default::Path::To::Second')).to be false
      expect(Object.const_defined?('TestSuites::Default::Path::To::SecondSibling')).to be false
    end

    it 'ignores files in "lib/" directories' do
      expect(@test_suite.class_names).not_to include 'TestSuites::Default::Lib::Ignored'
      expect(@test_suite.class_names).not_to include 'TestSuites::Default::Path::Lib::Ignored'
      expect(@test_suite.class_names).not_to include 'TestSuites::Default::Path::To::Lib::Ignored'
    end

    it 'creates test_case record' do
      # stored records
      #   root, individual, orphan, Path::To::First, Path::To::Second, Path::To::SecondSibling
      expect(TestCase.count).to be(6)
    end

    it 'makes Second as a child of First' do
      first = @test_suite.root.children.first
      second = first.children.first
      expect(second.parent).to eq first
    end

    it 'does not load malformed test cases' do
      @test_suite.unload
      path_to[:current_test_suite] = path_to[:test_suites].join('malformed')

      test_suite = TestSuite.new(path_to)
      test_suite.load
      expect(test_suite.root.descendants.count).to eq(1)
      expect(test_suite.individual.descendants.count).to eq(1)
      expect(test_suite.orphan.descendants.count).to eq(1)

      expect(Object.const_defined?('TestSuites::Malformed::AttackOnly')).to be true
      expect(Object.const_defined?('TestSuites::Malformed::TargetPortsAndAttackOnPort')).to be true
      expect(Object.const_defined?('TestSuites::Malformed::Orphan')).to be true

      expect(Object.const_defined?('TestSuites::Malformed::DoesNotInherit::Test')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::Individual::IsReservedName')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::InvalidMethodsDefined::All')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::InvalidMethodsDefined::AttackAndAttackOnPort')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::InvalidMethodsDefined::AttackAndTargetPorts')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::InvalidMethodsDefined::AttackOnPortOnly')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::InvalidMethodsDefined::NoMethods')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::InvalidMethodsDefined::TargetPortsOnly')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::UnexpectedName::Test')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::UnexpectedName::UnexpectedClassName')).to be false
      expect(Object.const_defined?('TestSuites::Malformed::UnexpectedName')).to be false
    end

    it 'removes invalid characters from test case paths' do
      @test_suite.unload
      path_to[:current_test_suite] = path_to[:test_suites].join('malformed-123%test@suite')
      test_suite = TestSuite.new(path_to)
      test_suite.load
      expect(test_suite.root.descendants.count).to eq(1)
      expect(test_suite.individual.descendants.count).to eq(0)
      expect(test_suite.orphan.descendants.count).to eq(0)

      expect(Object.const_defined?('TestSuites::Malformed123testsuite')).to be true
      expect(Object.const_defined?('TestSuites::Malformed123testsuite::TestCase')).to be true
      expect(Object.const_get('TestSuites::Malformed123testsuite').constants).to match_array(:TestCase)
    end
  end

  describe 'model instance function test' do
    let(:site) { create(:site) }
    let(:host) { create(:host, site: site) }

    before :each do
      @test_suite = TestSuite.new(path_to)
      @test_suite.load
      @first = @test_suite.root.children.first
      @second = @first.children.first
      @sibling = TestCase.find_by(name: 'TestSuites::Default::Path::To::SecondSibling')
    end

    after :each do
      @test_suite.unload
    end

    it '#show_tree shows tree' do
      lines = @test_suite.root.show_tree.lines.map(&:chomp)
      expect(lines[0]).to eq ' root'
      expect(lines[1]).to eq ' `--TestSuites::Default::Path::To::First'
      expect(lines[2]).to eq '    |--TestSuites::Default::Path::To::Second'
      expect(lines[3]).to eq '    `--TestSuites::Default::Path::To::SecondSibling'
    end

    it '#siblings returns siblings' do
      expect(@second.siblings.count).to eq(2)
      expect(@second.siblings).to match_array [@second, @sibling]
    end

    it '#clazz returns the test case\'s class' do
      expect(@second.clazz).is_a? TestSuites::Default::Path::To::First
    end

    it '#parent? returns if it has child' do
      expect(@first.parent?).to eq true
      expect(@second.parent?).to eq false
      expect(@sibling.parent?).to eq false
    end

    it '#instantiate returns a instance of the test case' do
      mutex = Mutex.new
      instance = @first.instantiate(host, path_to[:data].join('test'), path_to, console, mutex)
      expect(instance).is_a? TestSuites::Default::Path::To::First
    end
  end
end
