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
class CreateHosts < ActiveRecord::Migration[5.1]
  def self.up
    create_table :hosts do |t|
      t.belongs_to :site, index: true, null: false
      t.string :ip, null: false
      t.integer :test_status, default: 10, null: false

      t.timestamps null: false
    end
    add_foreign_key :hosts, :sites
    add_index :hosts, [:site_id, :ip], unique: true
  end

  def self.down
    drop_table :hosts
  end
end
