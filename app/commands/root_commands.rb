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
module RootCommands
  STRUCTURE = {
    dump:    { method: :root_dump,    help: 'display open ports of current site' },
    history: { method: :root_history, help: 'show command history' },
    toggle:  { method: :root_toggle,  help: 'toggle show/hide sub thread log message' },
    env:     { method: :root_env,     help: 'show environment variables' },
    quit:    { method: :root_quit,    help: 'Quit this application' },
    help:    { method: nil,           help: 'show help' }
  }.freeze

  #
  # Display open ports of current site
  #
  def root_dump(_)
    return unless Inspector.site_selected?(@site, @console)
    @site.hosts.all.order(:ip).each do |host|
      @console.info self, host.ports_table
    end
  end

  #
  # Show command history
  #
  def root_history(_)
    Readline::HISTORY.to_a.each.with_index(1) do |line, i|
      @console.info self, format(' %d %s', i, line)
    end
  end

  #
  # Toggle show/hide sub thread log message
  #
  def root_toggle(_)
    @console.show_thread_message = !@console.show_thread_message
    @console.info self, "Showing sub thread message : #{@console.show_thread_message}"
  end

  #
  # Show environment variables
  #
  def root_env(_)
    out = []

    out.concat RootPrivate.user

    out.concat RootPrivate.directories(@path_to)

    out.concat RootPrivate.database

    out.concat RootPrivate.environment(@env_config)

    @console.info self, out.join("\n")
  end

  #
  # Quit application
  #
  def root_quit(args)
    return unless tester_stop(args)

    @console&.close
    Thread.list.reject { |t| t == Thread.main }.each(&:kill)
    $stdout.puts 'done'
    exit
  end

  module RootPrivate
    def self.user
      ['User', " #{`whoami`.chomp} ", nil]
    end

    def self.directories(path_to)
      table = Terminal::Table.new do |t|
        path_to.each do |key, path|
          str = path.is_a?(Array) ? path.map(&:to_s).join("\n") : path.to_s
          t.add_row [key, str]
        end
      end

      ['Directories', table.to_s, nil]
    end

    def self.database
      db_config = ActiveRecord::Base.connection_config.reject { |key, _| key == :password }
      table = Terminal::Table.new(rows: db_config)

      ['Database', table.to_s, nil]
    end

    def self.environment(env_config)
      table = Terminal::Table.new(rows: env_config)

      ['Environment settings', table.to_s]
    end
  end
end
