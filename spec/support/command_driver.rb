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
module CommandDriver
  def self.configure
    suppress_output
    initialize_path
    initialize_console
    initialize_testers
    @env_config = CarashEnvironment.env_config
    @env_config['test_case_thread_limit'] = 5
    @db_config = CarashEnvironment.db_config
    @commands = Commands.load_commands(self, @path_to[:commands])
    @thread_manager = ThreadManager.new(@env_config['test_case_thread_limit'])
    @site_mutex = Mutex.new
    @site = nil
    enable_output
  end

  def self.call_command(args, answer: nil, wait_for: nil)
    @command_stdout = nil
    @command_stderr = nil
    @command_result = nil

    should_suppress = $stdout == STDOUT
    suppress_output if should_suppress

    $stdout.truncate(0)
    $stderr.truncate(0)
    $stdout.rewind
    $stderr.rewind

    original_stdin = capture_stdin(answer)

    cmd, args = @commands.recursive_search(args.shellsplit)
    @command_result = cmd.method.call(args)

    wait_for_stdout_to_print(wait_for)
    @command_stdout = $stdout.string.dup
    @command_stderr = $stderr.string.dup

    if CarashEnvironment.console.object_id != @console.object_id
      CarashEnvironment.console = @console
    end

    nil
  ensure
    enable_output if should_suppress
    enable_stdin(original_stdin)
  end

  def self.initialize_path
    @path_to = CarashEnvironment.path_to
  end

  def self.initialize_console
    @console = CarashEnvironment.console
  end

  def self.initialize_testers
    @testers = []
  end

  def self.stdout
    @command_stdout
  end

  def self.stderr
    @command_stderr
  end

  def self.result
    @command_result
  end

  def self.console
    @console
  end

  def self.site
    @site
  end

  def self.load_test_suite
    @test_suite = TestSuite.new(@path_to)
    @test_suite.load
  end

  def self.unload_test_suite
    @test_suite.unload
  end

  def self.remove_color_sequence(str)
    str.gsub(/\x1B\[([0-9?]{1,5}(;[0-9]{1,2})*)?[m|h]/, '')
  end

  def self.unselect_site
    return unless @site
    @console.close
    @path_to[:controller_log] = @path_to[:log].join('controller.log')
    clean_site_dir
    CarashEnvironment.initialize_console
    initialize_console
    @site = nil
  end

  def self.clean_site_dir
    FileUtils.rm_rf Dir.glob(@path_to[:result].join('sites', '*'))
  end

  def self.capture_stdin(answer)
    return nil unless answer
    original_stdin = $stdin
    answer = answer.join("\n") if answer.is_a? Array
    answer << "\n" unless answer[-1] == "\n"
    $stdin = StringIO.new(answer)
    original_stdin
  end
  private_class_method :capture_stdin

  def self.enable_stdin(original_stdin)
    $stdin = original_stdin if original_stdin
  end

  def self.wait_for_stdout_to_print(str)
    return unless str
    loop do
      sleep 0.1
      break if remove_color_sequence($stdout.string).match?(str)
    end
  end
  private_class_method :wait_for_stdout_to_print

end
