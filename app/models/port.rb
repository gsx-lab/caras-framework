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
class Port < ApplicationRecord
  belongs_to :host, required: true
  has_one :site, through: :host
  has_many :evidences, dependent: :destroy
  has_many :vulnerabilities, through: :evidences
  has_many :banners, dependent: :destroy

  validates :host, presence: true
  validates :proto, presence: true
  validates :proto, inclusion: { in: %w[tcp udp] }
  validates :no, presence: true
  validates :no, uniqueness: { scope: %i[host_id proto] }
  validates :no, inclusion: { in: 1..65535 }

  OPEN = :open
  CLOSED = :closed
  FILTERED = :filtered
  OPEN_FILTERED = :open_filtered

  def self.to_a_header
    %w[no state ssl? plain? nmap_service nmap_version]
  end

  def to_a
    [no, state, ssl, plain, service, nmap_service, nmap_version]
  end

  def to_s
    to_a.map(&:to_s).join(' ')
  end

  scope :ssl, ->() { where(ssl: true) }
  scope :plain, ->() { where(plain: true) }
  scope :service, ->(service_name) { where(service: service_name) }
  scope :nmap_service, ->(service_name) { where(nmap_service: service_name) }
  scope :open_ports, ->() { where(state: OPEN) }
end
