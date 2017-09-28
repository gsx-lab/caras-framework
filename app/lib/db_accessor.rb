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
require 'rubygems'
require 'bundler/setup'
require 'active_record'

module DbAccessor
  def self.conn(path_to, db_config, env_config)
    target_db_config = db_config[env_config['db_env']]
    adapter = target_db_config['adapter']
    unless adapter == 'postgresql'
      puts "Specified adapter #{adapter} is not supported."
      exit
    end
    target_db_config['host'] = ENV['DB_HOST'] if ENV['DB_HOST']
    target_db_config['port'] = ENV['DB_PORT'] if ENV['DB_PORT']
    initialize_active_record(path_to, db_config, target_db_config, env_config)
    load_models(path_to[:models])
  end

  def self.load_models(dir)
    Dir.glob(dir.join('**', '*.rb')).sort.each { |path| load path }
  end

  def self.initialize_active_record(path_to, db_config, target_db_config, env_config)
    ActiveRecord::Base.configurations = db_config
    ActiveRecord::Base.establish_connection(target_db_config)
    ActiveRecord::Base.logger = Logger.new(path_to[:activerecord_log], env_config['log_shift_age'])
    ActiveRecord::Base.logger.level = env_config['log_level']
    ActiveRecord::Base.default_timezone = :local
  end

  private_class_method :initialize_active_record
end
