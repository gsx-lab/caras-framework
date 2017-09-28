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

RSpec.describe SiteCommands do
  let(:site) { FactoryGirl.create(:site) }

  describe 'list' do
    context 'no site exists' do
      it 'shows no site' do
        call_command('site list')
        expect(command_stdout.lines.length).to be 3
      end
    end

    context 'one site exists' do
      before :each do
        site
      end

      it 'shows the site' do
        call_command('site list')
        site_name = command_stdout.lines[2].split(' ')[1]
        expect(site_name).to eq site.name
      end

      context 'the site is selected' do
        before :each do
          call_command('site select 1')
        end

        it 'shows the site as selected' do
          call_command('site list')
          site_info = command_stdout.lines[2].split(' ')
          expect(site_info.length).to eq 3
          expect(site_info[0]).not_to be nil
        end
      end
    end
  end

  describe 'select' do
    before :each do
      site
    end

    context 'argument is not valid number' do
      it 'should be error' do
        call_command('site select x')
        expect(command_stdout_mono.chomp).to eq 'x is not valid number nor in the Sites.'

        call_command('site select -1')
        expect(command_stdout_mono.chomp).to eq '-1 is not valid number nor in the Sites.'
      end
    end

    context 'name specified by argument is not in the Site' do
      it 'should be error' do
        invalid_site_name = site.name + 'x'
        call_command("site select #{invalid_site_name}")
        expect(command_stdout_mono.chomp).to eq "#{invalid_site_name} is not valid number nor in the Sites."
      end
    end

    context 'number is larger than site number' do
      it 'should be error' do
        large_number = Site.count + 1
        call_command("site select #{large_number}")
        expect(command_stdout_mono.chomp).to eq "#{large_number} is not valid number nor in the Sites."
      end
    end

    context 'select existing number' do
      before :each do
        call_command('site select 1')
      end

      it 'shows list of host' do
        expect(command_stdout_mono.lines[0].chomp.strip).to eq 'List of Host'
      end

      it 'selects the site' do
        expect(CommandDriver.site).to eq site
      end

      it 'changes console log file path' do
        expected_path = path_to[:result].join('sites', site.name, 'log', 'controller.log')
        expect(path_to[:controller_log]).to eq expected_path
      end
    end

    context 'select existing name' do
      before :each do
        call_command("site select #{site.name}")
      end
      it 'shows list of host' do
        expect(command_stdout_mono.lines[0].chomp.strip).to eq 'List of Host'
      end

      it 'selects the site' do
        expect(CommandDriver.site).to eq site
      end

      it 'changes console log file path' do
        expected_path = path_to[:result].join('sites', site.name, 'log', 'controller.log')
        expect(path_to[:controller_log]).to eq expected_path
      end
    end
  end

  describe 'new' do
    let(:site_name) { command_stdout_mono.chomp.match(/created a new site named (.+)/)[1] }

    context 'no argument' do
      it 'makes new site name' do
        call_command('site new')
        expect(site_name).not_to eq nil
      end

      it 'makes new site directory' do
        call_command('site new')
        expect(File).to exist(path_to[:result].join('sites', site_name))
      end

      it 'changes console log file path' do
        call_command('site new')
        expected_path = path_to[:result].join('sites', site_name, 'log', 'controller.log')
        expect(path_to[:controller_log]).to eq expected_path
      end
    end

    context 'with argument' do
      it 'makes new site with name specified' do
        call_command('site new new_site')
        expect(site_name).to eq 'new_site'
      end

      it 'makes new site directory' do
        call_command('site new new_site')
        expect(File).to exist(path_to[:result].join('sites', 'new_site'))
      end

      it 'changes console log file path' do
        call_command('site new new_site')
        expected_path = path_to[:result].join('sites', 'new_site', 'log', 'controller.log')
        expect(path_to[:controller_log]).to eq expected_path
      end

      it 'creates new record' do
        expect { call_command('site new new_site') }.to change(Site, :count).by(1)
      end

      context 'already existing directory same as new site name' do
        before :each do
          @existing = path_to[:result].join('sites', 'new_site')
          @existing.mkpath
          @existing.join('test').write('test file')
        end

        it 'shows message saying that the directory has been moved' do
          call_command 'site new new_site'

          expected_message = [
            @existing.to_s,
            ' has been moved to ',
            @existing.to_s + '_0'
          ].join

          expect(command_stdout_mono.lines[0].chomp).to eq expected_message
        end

        it 'moves directory' do
          call_command 'site new new_site'
          moved = path_to[:result].join('sites', 'new_site_0')
          expect(File).to exist(moved)
          expect(moved.join('test').read).to eq 'test file'
        end

        context 'already exists back up directories' do
          before :each do
            path_to[:result].join('sites', 'new_site_2').mkpath
          end

          it 'moves directory to other it has maximum number' do
            call_command 'site new new_site'
            moved = path_to[:result].join('sites', 'new_site_3')
            expect(File).to exist(moved)
          end
        end
      end
    end
  end

  describe 'delete' do
    before :each do
      site
    end

    context 'specified by number' do
      it 'inquiry about to delete' do
        call_command('site delete 1', answer: 'Y')
        expect(command_stdout_mono.lines.last.chomp).to eq 'Really want to delete this site? [Y/n] > Y'
      end

      it 'does not delete site when answer n' do
        expect { call_command('site delete 1', answer: 'n') }.to change(Site, :count).by(0)
      end

      it 'deletes site when answer "Y"' do
        expect { call_command('site delete 1', answer: 'Y') }.to change(Site, :count).by(-1)
      end

      it 'also deletes site when answer "y"' do
        expect { call_command('site delete 1', answer: 'y') }.to change(Site, :count).by(-1)
      end

      it 'does not delete invalid number' do
        invalid_number = Site.all.count + 1
        expect { call_command("site delete #{invalid_number}", answer: 'y') }.to change(Site, :count).by(0)
      end
    end

    context 'specified by name' do
      it 'inquiry about to delete' do
        call_command("site delete #{site.name}", answer: 'Y')
        expect(command_stdout_mono.lines.last.chomp).to eq 'Really want to delete this site? [Y/n] > Y'
      end

      it 'does not delete site when answer n' do
        expect { call_command("site delete #{site.name}", answer: 'n') }.to change(Site, :count).by(0)
      end

      it 'deletes site when answer "Y"' do
        expect { call_command("site delete #{site.name}", answer: 'Y') }.to change(Site, :count).by(-1)
      end

      it 'also deletes site when answer "y"' do
        expect { call_command("site delete #{site.name}", answer: 'y') }.to change(Site, :count).by(-1)
      end

      it 'does not delete invalid name' do
        invalid_name = site.name + 'x'
        expect { call_command("site delete #{invalid_name}", answer: 'y') }.to change(Site, :count).by(0)
      end
    end
  end
end
