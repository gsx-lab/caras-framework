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
module TerminalSupport
  #
  # return git instance if path is on git repository
  #
  def self.git_repo(git_path)
    Git.open(git_path)
  rescue ArgumentError
    nil
  end

  #
  # return most recent tag if it has
  #
  def self.describe_repo(repo)
    repo&.describe('HEAD')
  rescue Git::GitExecuteError
    nil
  end

  #
  # generate simple terminal table from ActiveRecord::Relation instance
  #
  def self.table(records, column, with_check_sign: false, selected: nil)
    list = Terminal::Table.new do |t|
      records.each.with_index(1) do |record, index|
        row = [{ value: index, alignment: :right }, record.public_send(column)]
        row.unshift(check_sign(record, selected)) if with_check_sign
        t.add_row row
      end
    end
    list.title = "List of #{records.model_name.human}"
    list.style = { border_top: false, border_x: '', border_y: '', border_i: '' }
    list
  end

  #
  # Returns checked sign if parameters are equal
  #
  def self.check_sign(left, right)
    left == right ? "\xE2\x9C\x94" : nil
  end
end
