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
module ReportCommands
  STRUCTURE = {
    report: {
      method: nil, help: 'manage report',
      children: {
        current: { method: :report_current, help: 'show current report template' },
        list:    { method: :report_list,    help: 'show report templates' },
        select:  { method: :report_select,  help: 'select report template' },
        create:  { method: :report_create,  help: 'create a report for current site' },
        help:    { method: nil,             help: 'show help' },
        exit:    { method: nil,             help: 'exit from report mode' }
      }
    }
  }.freeze

  #
  # Show current report template
  #
  def report_current(_)
    report_list(nil) do |report_templates|
      report_templates.reject { |rt| rt[:sign].nil? }
    end
  end

  #
  # List of report templates
  #
  def report_list(_)
    report_templates = ReportPrivate.all_report_templates(@path_to)
    report_templates = yield(report_templates) if block_given?
    @console.info self, ReportPrivate.table(report_templates)
  end

  #
  # Select report template
  #
  def report_select(args)
    report_templates = ReportPrivate.all_report_templates(@path_to)
    target_template = Selector.from_array(report_templates, :relative_path, args, @console, name: 'report templates')
    return unless target_template

    @path_to[:current_report_template] = target_template[:path]
    @path_to[:current_report_template_dir] = target_template[:path].dirname
    report_current(nil)
  end

  #
  # create a report
  #
  def report_create(_)
    return unless Inspector.site_selected?(@site, @console)

    @site.reload
    Slim::Engine.options[:pretty] = true

    begin
      report = Slim::Template.new(@path_to[:current_report_template]).render(self)
    rescue SyntaxError => e
      @console.fatal self, e
    end

    report_path = ReportPrivate.write(@path_to, @site, report)

    # Open file if running on macOS
    `open '#{report_path}'` if @env_config['db_env'] != 'test' && RUBY_PLATFORM.match?('darwin')
    @console.info self, "Report is created in #{report_path}"
  end

  module ReportPrivate
    def self.write(path_to, site, report)
      report_path = path_to_report(path_to, site)
      FileUtils.mkdir_p(report_path.parent) unless File.directory?(report_path.parent)
      File.write(report_path, report)
      report_path
    end

    def self.table(report_templates)
      rows = report_templates.map do |row|
        [
          row[:sign],
          row[:index],
          row[:relative_path],
          row[:remote],
          row[:branch],
          row[:describe]
        ]
      end

      table = Terminal::Table.new(rows: rows)
      table.headings = [nil, 'No', 'Path', 'RemoteUrl', 'Branch', 'Describe']
      table
    end

    def self.all_report_templates(path_to)
      report_templates = []

      report_templates << info(path_to, path_to[:default_report_template], 1)

      template_files = enum_template_files(path_to[:report_templates_dir])

      template_files.each.with_index(2) do |p, index|
        report_templates << info(path_to, p, index)
      end

      report_templates
    end

    def self.enum_template_files(dir)
      Inspector.glob_except_libs(dir, '*.slim').map { |p| Pathname.new(p) }
    end

    def self.path_to_report(path_to, site)
      extname = path_to[:current_report_template].basename('.slim').extname
      extname = '.html' if extname.empty?
      filename = 'report_' + Time.now.strftime('%Y%m%d-%H%M%S') + extname
      path_to[:data].join(site.name).join(filename)
    end
    private_class_method :path_to_report

    def self.info(path_to, path, index)
      relative_path, git_path = resolve_paths(path_to, path)
      repo = TerminalSupport.git_repo(git_path)

      {
        sign: TerminalSupport.check_sign(path_to[:current_report_template], path),
        index: index,
        path: path,
        relative_path: relative_path.to_s,
        remote: repo&.remote&.url,
        branch: repo&.current_branch,
        describe: TerminalSupport.describe_repo(repo)
      }
    end
    private_class_method :info

    def self.resolve_paths(path_to, path)
      if path == path_to[:default_report_template]
        relative_path = path.relative_path_from(path_to[:app].join('report_templates'))
        git_path = path_to[:base]
      else
        relative_path = path.relative_path_from(path_to[:ext].join('report_templates'))
        git_path = path.dirname
      end

      [relative_path, git_path]
    end
    private_class_method :resolve_paths
  end
end
