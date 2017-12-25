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
require 'shellwords'
require 'timeout'
require 'thread'
require 'mutex_m'
require 'ipaddress'
require 'pathname'
require 'readline'
require 'active_support'
require 'active_support/core_ext'
require 'filemagic'
require 'cgi'
require 'base64'
require 'sys/proctree'
require 'yaml'

require_relative 'commands'
require_relative 'console'
require_relative 'inspector'
require_relative 'inquiry'
require_relative 'path_initializer'
require_relative 'selector'
require_relative 'terminal_support'
require_relative 'test_case_template'
require_relative 'test_suite'
require_relative 'tester'
require_relative 'db_accessor'
require_relative 'thread_manager'

class Controller
  VERSION = '1.0.1'.freeze

  attr_reader :env_config
  PROMPT = '%s%s ' + case `whoami`.chomp
                     when 'root' then '# '
                     else; '$ '
                     end

  def initialize
    initialize_paths
    load_configuration
    require_additional_gems
    initialize_console
    initialize_database
    initialize_commands
    initialize_threads
    initialize_host_statuses
    initialize_test_suite
    greeting
  end

  #
  # parse and execute commands
  #
  def run(mode, commands = @commands)
    completion(commands)

    loop do
      response = @console.readline(format_prompt(mode))
      # show help
      if response[:words][0] == 'help'
        help(response[:words], commands)
        next
      end

      cmd, args = commands.recursive_search(response[:words])

      break if should_exit?(cmd, commands)

      distribute_command(cmd, args, mode, commands, response)
    end
  end

  private

  def should_exit?(cmd, commands)
    # @commands is top level commands
    # if exit and mode is not toplevel, move to upper mode
    cmd&.name == 'exit' && commands != @commands
  end

  def distribute_command(cmd, args, mode, commands, response)
    if cmd&.method
      # call method if it exists
      call_command(cmd, args)

    elsif cmd&.parent? && args.empty?
      # no method but have child, move to sub command mode
      move_to_sub_command(cmd, mode, commands)

    elsif cmd&.name == 'help'
      help(args, cmd.parent.children)

    else
      # failed anything
      failed_to_call_command(commands, response)
    end
  end

  def move_to_sub_command(cmd, mode, commands)
    run(mode + '/' + cmd.name, cmd.children)
    completion(commands)
  end

  def call_command(cmd, args)
    cmd.method.call(args)
  rescue StandardError => e
    @console.fatal self, e
  end

  def failed_to_call_command(commands, response)
    response[:line] = response[:line][0, 10] + '...' if response[:line].size > 10
    @console.warn self, "unknown command: #{response[:line]}"
    help(response[:words], commands)
  end

  def format_prompt(mode)
    name = @site ? " [#{@site.name}]" : nil
    format(PROMPT, mode, name)
  end

  def completion(commands)
    Readline.completion_proc = proc do |input|
      words = Readline.line_buffer.shellsplit

      last = words.pop
      cmds = commands_for_completion(commands, words)

      if cmds
        # if matched, use children
        cmd = cmds.find { |c| c.name == last }
        cmds = cmd.children if cmd

        # search input words on command array
        cmds.names.grep(/\A#{Regexp.quote input}/)
      end
    end
  end

  def commands_for_completion(cmds, words)
    words.each do |word|
      cmd = cmds.find { |c| c.name == word }
      unless cmd
        cmds = nil
        break
      end
      cmds = cmd.children
    end
    cmds
  end

  def help(_, commands)
    c = {}
    commands.each do |cmd|
      c[cmd.name.to_s] = cmd.description
    end
    table = Terminal::Table.new(title: 'supported commands', rows: c)
    table.style = { border_top: false, border_x: '', border_y: '', border_i: '' }
    @console.info self, table.to_s
  end

  def initialize_paths
    @path_to = PathInitializer.path(__FILE__)
  end

  def load_configuration
    @env_config = YAML.load_file(@path_to[:environment_config])

    # set default
    unless Console::SHIFT_AGES.include?(env_config['log_shift_age'])
      @env_config['log_shift_age'] = 'daily'
    end
    unless Console::LEVELS.include?(env_config['log_level'])
      @env_config['log_level'] = :info
    end

    @db_config = YAML.load_file(@path_to[:database_config])
  end

  def require_additional_gems
    Bundler.require(@env_config['environment'])
  end

  def initialize_console
    @path_to[:log].mkpath unless @path_to[:log].directory?

    @console = Console.new(@path_to[:controller_log], @env_config)
  end

  def initialize_database
    DbAccessor.conn(@path_to, @db_config, @env_config)
  end

  def initialize_commands
    @commands = Commands.load_commands(self, @path_to[:commands])
  end

  def initialize_threads
    @testers = []
    @thread_manager = ThreadManager.new(@env_config['test_case_thread_limit'])
    @site_mutex = Mutex.new
  end

  def initialize_host_statuses
    Host.where(test_status: :testing).update(test_status: :aborted)
  end

  def initialize_test_suite
    @test_suite = TestSuite.new(@path_to)
    result = @test_suite.load
    return unless result[:error?]

    @console.error self, @test_suite.result_to_s[:error]
  end

  def greeting
    message =
      [
        "Welcome to carash #{VERSION}.",
        'Now no site is selected.',
        'You must create a new site with following command.',
        ' $ site new Site-1',
        'Or you can select one from existing sites.',
        ' $ site list',
        ' $ site select 1',
        'Enjoy!'
      ].join("\n")
    @console.info self, message
  end
end
