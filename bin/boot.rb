#!/usr/bin/env ruby
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
require 'pathname'
script_path = Pathname.new(__FILE__).realpath.expand_path

ENV['BUNDLE_GEMFILE'] = script_path.parent.parent.join('Gemfile').to_s

require 'bundler'
Bundler.require(:default)

require_relative '../app/lib/controller.rb'

controller = Controller.new
if ENV['DEBUG'] == '1' && controller.env_config['environment'] == 'development'
  pry
else
  controller.run('carash')
end
