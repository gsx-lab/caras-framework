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
module PathInitializer
  def self.path(script)
    script = Pathname.new(script).realpath.expand_path

    path_to = application_core_paths(script)
    configuration_files(path_to)
    extensions_paths(path_to)
    working_paths(path_to)
    path_to
  end

  def self.application_core_paths(script)
    path_to = {}

    path_to[:script] = script
    path_to[:base] = script.parent.parent.dirname
    %I[app ext test_suites db config node_modules].each do |key|
      path_to[key] = path_to[:base].join(key.to_s)
    end

    path_to[:models] = path_to[:app].join('models')
    path_to[:commands] = [path_to[:app].join('commands'), path_to[:ext].join('commands')]
    path_to
  end
  private_class_method :application_core_paths

  def self.configuration_files(path_to)
    path_to[:database_config] = path_to[:config].join('database.yml')
    path_to[:environment_config] = path_to[:config].join('environment.yml')
  end
  private_class_method :configuration_files

  def self.extensions_paths(path_to)
    path_to[:current_test_suite] = path_to[:test_suites].join('default')
    path_to[:report_templates_dir] = path_to[:ext].join('report_templates')
    path_to[:default_report_template] = path_to[:app].join('report_templates', 'default.html.slim')
    path_to[:current_report_template] = path_to[:default_report_template]
    path_to[:current_report_template_dir] = path_to[:current_report_template].dirname
  end
  private_class_method :extensions_paths

  def self.working_paths(path_to)
    path_to[:cwd] = Pathname.new(Dir.pwd)
    path_to[:result] = path_to[:cwd].join('result')
    path_to[:data] = path_to[:result].join('sites')
    path_to[:log] = path_to[:result].join('log')

    # files
    path_to[:controller_log] = path_to[:log].join('controller.log')
    path_to[:activerecord_log] = path_to[:log].join('activerecord.log')
  end
  private_class_method :working_paths
end
