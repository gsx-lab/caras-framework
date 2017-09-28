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
module CarashEnvironment
  def self.configure
    initialize_path
    load_configuration
    setup_bundler
    rsync_extensions
    initialize_database
    initialize_console
  end

  def self.path_to
    @path_to
  end

  def self.db_config
    @db_config
  end

  def self.env_config
    @env_config
  end

  def self.console
    @console
  end

  def self.console=(console)
    @console = console
  end

  def self.make_path
    @test_dir.mkpath unless @test_dir.exist?
    @path_to[:log].mkpath unless @path_to[:log].exist?
  end

  def self.rm_test_dir
    FileUtils.rm_rf(@test_dir)
  end

  def self.close_console
    @console&.close
  end

  def self.close_connection
    ActiveRecord::Base.connection.close
  end

  def self.script_path
    @script_path || Pathname.new(__FILE__).realpath.expand_path.parent.parent.parent.join('app', 'lib', 'controller.rb')
  end
  private_class_method :script_path

  def self.setup_bundler
    ENV['BUNDLE_GEMFILE'] = script_path.parent.parent.join('Gemfile').to_s
    require 'bundler'
    Bundler.require(:default)
    Bundler.require(@env_config['environment'])
  end
  private_class_method :setup_bundler

  def self.initialize_path
    path_to = PathInitializer.path(script_path)

    @test_dir = path_to[:base].join('tmp', 'test')
    @test_dir.mkpath unless @test_dir.exist?

    path_to[:cwd] = path_to[:base].join('tmp', 'test')
    path_to[:result] = path_to[:cwd].join('result')
    path_to[:data] = path_to[:result].join('sites')
    path_to[:log] = path_to[:result].join('log')

    path_to[:controller_log] = path_to[:log].join('controller.log')
    path_to[:activerecord_log] = path_to[:log].join('activerecord.log')

    path_to[:test_suites] = @test_dir.join('test_suites')
    path_to[:current_test_suite] = path_to[:test_suites].join('default')
    path_to[:ext] = @test_dir.join('ext')
    path_to[:commands] = [path_to[:app].join('commands'), path_to[:ext].join('commands')]
    path_to[:report_templates_dir] = path_to[:ext].join('report_templates')

    @path_to = path_to
    @path_to[:log].mkpath unless @path_to[:log].exist?
  end

  def self.rsync_extensions
    Rsync.run(@path_to[:base].join('spec', 'fixtures', 'test_suites'), @path_to[:test_suites].parent, '--delete -a')
    Rsync.run(@path_to[:base].join('spec', 'fixtures', 'ext'), @path_to[:ext].parent, '--delete -a')
  end

  def self.load_configuration
    db_config = YAML.load_file(@path_to[:database_config])
    env_config = YAML.load_file(@path_to[:environment_config])
    env_config['db_env'] = ENV['DB_ENV'] || 'test'
    env_config['environment'] = ENV['ENVIRONMENT'] || 'test'
    @db_config = db_config
    @env_config = env_config
  end
  private_class_method :load_configuration

  def self.initialize_database
    DbAccessor.conn(@path_to, @db_config, @env_config)
    ActiveRecord::Migration.maintain_test_schema!
  end
  private_class_method :initialize_database

  def self.initialize_console
    # initialize console
    @console = Console.new(path_to[:controller_log], env_config)
  end
end
