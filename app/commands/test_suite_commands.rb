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
module TestSuiteCommands
  STRUCTURE = {
    testsuite: {
      method: nil, help: 'manage test suites',
      children: {
        current: { method: :test_suite_current, help: 'show current test suite info' },
        list:    { method: :test_suite_list,    help: 'test suites list' },
        reload:  { method: :test_suite_reload,  help: 'reload current test suite' },
        select:  { method: :test_suite_select,  help: 'select other test suite' },
        pull:    { method: :test_suite_pull,    help: 'git pull current test suite' },
        help:    { method: nil,                 help: 'show help' },
        exit:    { method: nil,                 help: 'exit from testsuite mode' }
      }
    }
  }.freeze

  #
  # show current test suite
  #
  def test_suite_current(_)
    current = TestSuitePrivate.all_test_suites(@path_to).find { |ts| !ts[:sign].nil? }
    @console.info self, TestSuitePrivate.table([current])
  end

  #
  # list of loadable test suites
  #
  def test_suite_list(_)
    test_suites = TestSuitePrivate.all_test_suites(@path_to)
    @console.info self, TestSuitePrivate.table(test_suites)
  end

  #
  # reload test suite
  #
  def test_suite_reload(_)
    return if Inspector.running_any?(@testers, @console)

    test_suite = TestSuitePrivate.reload_suite(@console, @test_suite, @path_to)
    @test_suite = test_suite if test_suite
  end

  #
  # load specified test suite
  #
  def test_suite_select(args)
    return if Inspector.running_any?(@testers, @console)
    test_suites = TestSuitePrivate.all_test_suites(@path_to)
    target_suite = Selector.from_array(test_suites, :basename, args, @console, name: 'TestSuites')
    return unless target_suite

    test_suite = TestSuitePrivate.reload_suite(@console, @test_suite, @path_to, target_suite[:dir])
    @test_suite = test_suite if test_suite
    test_suite_current(nil)
  end

  #
  # git pull test suite
  #
  def test_suite_pull(_)
    git = Git.open(@path_to[:current_test_suite])
    @console.info self, git.pull(git.remote, git.current_branch)
  end

  module TestSuitePrivate
    def self.reload_suite(console, test_suite, path_to, new_test_suite_dir = nil)
      test_suite = change_suite(console, test_suite, path_to, new_test_suite_dir)
      return nil unless test_suite

      test_suite.reload

      show_change_result(console, test_suite)
      test_suite
    end

    def self.change_suite(console, test_suite, path_to, new_test_suite_dir)
      return test_suite unless new_test_suite_dir
      return test_suite if path_to[:current_test_suite] == new_test_suite_dir

      old_test_suite_dir = path_to[:current_test_suite]

      path_to[:current_test_suite] = new_test_suite_dir

      begin
        new_test_suite = TestSuite.new(path_to)
      rescue StandardError => e
        console.error self, e.to_s
        path_to[:current_test_suite] = old_test_suite_dir
        return nil
      end

      new_test_suite
    end

    private_class_method :change_suite

    def self.show_change_result(console, test_suite)
      result = test_suite.result_to_s
      console.info self, result[:info] if result[:info].length.positive?
      console.error self, result[:error] if result[:error].length.positive?
    end

    private_class_method :show_change_result

    def self.info(path_to, path, index)
      repo = TerminalSupport.git_repo(path)
      {
        sign: TerminalSupport.check_sign(path_to[:current_test_suite], path),
        index: index,
        dir: path,
        basename: path.basename.to_s,
        count: Dir.glob(path.join('**', '*.rb')).count,
        remote: repo&.remote&.url,
        branch: repo&.current_branch,
        describe: TerminalSupport.describe_repo(repo)
      }
    end

    private_class_method :info

    def self.all_test_suites(path_to)
      test_suites = []
      directories(path_to).each.with_index(1) do |path, index|
        test_suites << info(path_to, path, index)
      end
      test_suites
    end

    def self.table(rows)
      rows = rows.map do |row|
        [
          row[:sign],
          row[:index],
          row[:basename],
          row[:count],
          row[:remote],
          row[:branch],
          row[:describe]
        ]
      end

      table = Terminal::Table.new(rows: rows)
      table.headings = [nil, 'No', 'Dir', 'Tests', 'RemoteUrl', 'Branch', 'Describe']
      table
    end

    def self.directories(path_to)
      Dir.glob(path_to[:test_suites].join('*')).sort.map { |p| Pathname.new(p) }
    end

    private_class_method :directories
  end
end
