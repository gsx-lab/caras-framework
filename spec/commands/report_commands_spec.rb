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

RSpec.describe ReportCommands do
  let(:site) { create(:site) }
  let(:host) { create(:host, site: site) }
  let(:all_templates) {
    templates = Pathname.glob(path_to[:report_templates_dir].join('**', '*.slim')).map { |p| p.relative_path_from(path_to[:report_templates_dir]).to_s }
    templates.append(path_to[:default_report_template].basename.to_s)
    templates.reject! { |p| p.match?('/lib/') }
  }

  describe 'current' do
    it 'shows current report template' do
      call_command('report current')
      default = path_to[:current_report_template].basename.to_s
      line = command_stdout_mono.lines.select { |l| l.include?(default) }
      expect(line).not_to be nil
      expect(command_stdout_mono.lines.length).to be 5
    end
  end

  describe 'list' do
    it 'shows all report template' do
      # determine report template names
      call_command('report list')

      # extract "Path" field
      lines = command_stdout_mono.lines[3..-2].map { |l| l.split('|').map(&:strip) }.map { |l| l[3] }

      expect(lines).to match_array all_templates
    end

    it 'shows as checked for current report template' do
      current = path_to[:current_report_template].relative_path_from(path_to[:current_report_template_dir]).basename.to_s

      call_command('report list')

      lines = command_stdout_mono.lines[3..-2].map { |line| line.split('|').map(&:strip) }
      current_line = lines.find { |line| line[3] == current }
      expect(current_line[1]).not_to be_empty
    end
  end

  describe 'select' do
    context 'specified by number' do
      it 'changes current report template' do
        before = path_to[:current_report_template].dup
        call_command('report select 2')
        after = path_to[:current_report_template].dup
        expect(before).not_to eq after
      end

      it 'does not change if specified number is not exist' do
        invalid_number = all_templates.length + 1
        call_command("report select #{invalid_number}")
        expect(command_stdout_mono.chomp).to eq("#{invalid_number} is not valid number nor in the report templates.")
      end
    end

    context 'specified by path' do
      it 'changes current report template' do
        before = path_to[:current_report_template].dup
        call_command('report select spec/my.html.slim')
        after = path_to[:current_report_template].dup
        expect(before).not_to eq after
      end

      it 'does not change if specified name is not exist' do
        invalid_path = 'non-existent/report_templates.html.slim'
        call_command("report select #{invalid_path}")
        expect(command_stdout_mono.chomp).to eq("#{invalid_path} is not valid number nor in the report templates.")
      end
    end
  end

  describe 'create' do
    context 'no site selected' do
      it 'warns to select site first' do
        call_command('report create')
        expect(command_stdout_mono.chomp).to eq('Select site first')
      end
    end

    context 'after select site' do
      before :each do
        host
        call_command('site select 1')
      end

      it 'creates new report file' do
        call_command('report create')
        expect(command_stdout_mono).to start_with('Report is created in')
        path = command_stdout_mono.chomp.split(' in ')[1]
        expect(File).to exist(path)
      end
    end
  end
end
