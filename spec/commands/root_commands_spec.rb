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
require_relative '../command_helper'

RSpec.describe RootCommands do
  describe 'toggle' do
    it 'changes show_thread_message flag' do
      before = console.show_thread_message
      call_command('toggle')
      expect(console.show_thread_message).to be !before
    end
  end

  describe 'quit' do
    it 'raises SystemExit' do
      expect { call_command('quit') }.to raise_error SystemExit
    end
  end
end
