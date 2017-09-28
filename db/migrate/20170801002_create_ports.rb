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
class CreatePorts < ActiveRecord::Migration[5.1]
  def self.up
    create_table :ports do |t|
      t.belongs_to :host, index: true, null: false
      t.string :proto, null: false
      t.integer :no, null: false
      t.boolean :ssl
      t.boolean :plain
      t.string :state
      t.string :service
      t.string :nmap_service
      t.string :nmap_version

      t.timestamps null: false
    end
    add_index :ports, [:host_id, :proto, :no], unique: true
    add_foreign_key :ports, :hosts
  end

  def self.down
    drop_table :ports
  end
end
