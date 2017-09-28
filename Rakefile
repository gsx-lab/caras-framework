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
require 'yaml'
require 'logger'
require 'active_record'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new('spec')

namespace :db do
  def database_exists?
    ActiveRecord::Base.connection
  rescue ActiveRecord::NoDatabaseError
    false
  else
    true
  end

  def create_database_if_not_exist(config)
    options = { template: 'template0' }

    return if database_exists?

    create_user_if_not_exists(config)
    create_database(config, options)
  end

  def create_database(config, options)
    ActiveRecord::Base.establish_connection config.merge('database' => 'postgres')
    ActiveRecord::Base.connection.create_database config['database'], options
    ActiveRecord::Base.establish_connection config
  end

  def create_user_if_not_exists(config)
    sql = <<~SQL
      do $$
      BEGIN
        IF NOT EXISTS (
             SELECT * FROM pg_catalog.pg_user WHERE usename = '#{config['username']}'
           ) THEN
           CREATE USER #{config['username']} WITH CREATEDB LOGIN PASSWORD '#{config['password']}';
        END IF;
      END
      $$
    SQL

    execute_with_admin(config) do
      ActiveRecord::Base.connection.execute sql
    end
  end

  def execute_with_admin(config)
    ActiveRecord::Base.establish_connection config.merge('database' => 'postgres', 'username' => PSQL_USER, 'password' => nil)
    yield
  end

  def any_pending_migrations?
    pending = ActiveRecord::Migrator.open(ActiveRecord::Migrator.migrations_paths).pending_migrations

    if pending.any?
      puts "You have #{pending.size} pending migration#{pending.size.positive? ? 's' : ''}"
      pending.each do |migration|
        printf "  %4d %s\n", migration.version, migration.name
      end
      true
    else
      false
    end
  end

  def copy_if_not_exist(src, dst)
    FileUtils.copy(src, dst, preserve: true) unless dst.exist?
  end

  task :configuration do
    # create environment.yml and database.yml if not exists
    conf_dir = Pathname.new('config')

    env_conf_sample = conf_dir.join('environment.yml.sample')
    env_conf_file = conf_dir.join('environment.yml')
    copy_if_not_exist(env_conf_sample, env_conf_file)
    @env_config = YAML.load_file(env_conf_file)

    db_conf_sample = conf_dir.join('database.yml.sample')
    db_conf_file = conf_dir.join('database.yml')
    copy_if_not_exist(db_conf_sample, db_conf_file)
    @configs = YAML.load_file(db_conf_file)

    DB_ENV = ENV['DB_ENV'] || @env_config['db_env']

    if DB_ENV.nil?
      puts 'Specify DB_ENV parameter. e.g. bundle exec rake db:setup DB_ENV=production'
      exit
    end

    unless @configs.keys.include? DB_ENV
      puts "Choose DB_ENV key from one : #{@configs.keys.join ', '}"
      exit
    end

    PSQL_USER = ENV['PSQL_USER'] || 'postgres'
    MIGRATIONS_DIR = 'db/migrate'.freeze
    SCHEMA = 'db/schema.rb'.freeze
    @config = @configs[DB_ENV]
    @config['host'] = ENV['DB_HOST'] if ENV['DB_HOST']
    @config['port'] = ENV['DB_PORT'] if ENV['DB_PORT']
  end

  task configure_connection: :configuration do
    unless @config['adapter'] == 'postgresql'
      puts "Specified adapter #{@config['adapter']} is not supported."
      exit
    end

    LOGGER = (ENV['LOGGER'] == 'true') || @config['logger']

    ActiveRecord::Base.configurations = @configs
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = Logger.new STDOUT if LOGGER
  end

  desc 'Create environment.yml, create database from config/database.yml for specified DB_ENV'
  task setup: :configuration do
    Rake::Task['db:create'].invoke

    if !File.exist?(SCHEMA) || any_pending_migrations?
      Rake::Task['db:migrate'].invoke
      Rake::Task['schema:dump'].invoke
    end
  end

  desc 'Create the database from config/database.yml for the current db_env'
  task create: :configure_connection do
    create_database_if_not_exist(@config)
  end

  desc 'Drops the database for the current db_env'
  task drop: :configuration do
    execute_with_admin @config do
      version_num = Integer((ActiveRecord::Base.connection.execute 'SHOW server_version_num').first.values.first)
      pid_str = version_num < 90200 ? 'procpid' : 'pid'
      sql = <<-SQL
        SELECT pg_terminate_backend(#{pid_str})
          FROM pg_stat_activity
         WHERE datname = '#{@config['database']}'
           AND #{pid_str} <> pg_backend_pid()
      SQL
      ActiveRecord::Base.connection.execute sql
      ActiveRecord::Base.connection.drop_database @config['database']
    end
  end

  desc 'Drops the database user for the current db_env'
  task drop_user: :configuration do
    execute_with_admin @config do
      ActiveRecord::Base.connection.execute "DROP USER IF EXISTS #{@config['username']}"
    end
  end

  desc 'Creates the database user for the current db_env'
  task create_user: :configuration do
    execute_with_admin @config do
      ActiveRecord::Base.connection.execute "CREATE USER #{@config['username']} CREATEDB LOGIN PASSWORD '#{@config['password']}'"
    end
  end

  desc 'Migrate the database (options: VERSION=x).'
  task migrate: :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil
    Rake::Task['schema:dump'].invoke
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n)'
  task rollback: :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
    Rake::Task['schema:dump'].invoke
  end

  desc 'Retrieves the current schema version number'
  task version: :configure_connection do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end
end

namespace :schema do
  desc 'Create a db/schema.rb file that is portable against any DB supported by AR'
  task dump: 'db:configure_connection' do
    require 'active_record/schema_dumper'
    File.open(SCHEMA, 'w:utf-8') do |file|
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, file)
    end
    Rake::Task['schema:dump'].reenable
  end

  desc 'Load a schema.rb file into the database'
  task load: 'db:configure_connection' do
    ActiveRecord::Tasks::DatabaseTasks.load_schema(@config, :ruby, SCHEMA)
    ActiveRecord::Base.establish_connection(@config)
  end
end
