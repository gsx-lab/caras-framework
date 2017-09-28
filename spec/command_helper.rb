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
require_relative './app_helper'
require_relative './support/command_driver'

module CommandHelper
  CommandDriver.configure

  def call_command(args, answer: nil, wait_for: nil)
    CommandDriver.call_command(args, answer: answer, wait_for: wait_for)
  end

  def command_stdout
    CommandDriver.stdout
  end

  def command_stdout_mono
    CommandDriver.remove_color_sequence(command_stdout)
  end

  def command_stderr
    CommandDriver.stderr
  end

  def command_stderr_mono
    CommandDriver.remove_color_sequence(command_stderr)
  end

  def command_result
    CommandDriver.result
  end
end

RSpec.configure do |config|
  config.include CommandHelper

  config.before :each do
    CommandDriver.initialize_path
    CommandDriver.initialize_console
    CommandDriver.initialize_testers
    CommandDriver.load_test_suite
    CommandDriver.unselect_site
  end

  config.after :each do
    CommandDriver.unload_test_suite
  end
end
