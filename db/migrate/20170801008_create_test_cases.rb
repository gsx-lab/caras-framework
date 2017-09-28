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
class CreateTestCases < ActiveRecord::Migration[5.1]
  def self.up
    create_table :test_cases do |t|
      t.integer :dangles, default: nil
      t.boolean :root, null: false
      t.integer :parent_id
      t.string :name, null: false
      t.string :requires
      t.boolean :runs_per_port
      t.string :protocol
      t.string :description
      t.string :author

      t.timestamps null: false
    end
    add_foreign_key :test_cases, :test_cases, column: :parent_id
  end

  def self.down
    drop_table :test_cases
  end
end
