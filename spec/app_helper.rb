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
require_relative './spec_helper'
require_relative '../app/lib/controller'
require_relative './support/suppress_output'
require_relative './support/carash_environment'

module CarashHelper
  CarashEnvironment.configure

  def path_to
    CarashEnvironment.path_to
  end

  def db_config
    CarashEnvironment.db_config
  end

  def env_config
    CarashEnvironment.env_config
  end

  def console
    CarashEnvironment.console
  end
end

RSpec.configure do |config|
  config.include CarashHelper
  config.include FactoryGirl::Syntax::Methods

  config.before :suite do
    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
    FactoryGirl.find_definitions
  end

  config.before :each do
    DatabaseCleaner.start
    CarashEnvironment.initialize_path
    CarashEnvironment.initialize_console
    CarashEnvironment.rsync_extensions
  end

  config.after :each do
    DatabaseCleaner.clean
    CarashEnvironment.close_console
  end

  config.after :suite do
    CarashEnvironment.rm_test_dir
    CarashEnvironment.close_connection
  end
end
