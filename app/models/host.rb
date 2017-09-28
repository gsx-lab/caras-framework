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
require 'resolv'

class Host < ApplicationRecord
  default_scope -> { order('inet(ip)') }
  belongs_to :site, required: true
  has_many :hostnames, dependent: :destroy
  has_many :ports, dependent: :destroy
  has_many :evidences, dependent: :destroy
  has_many :vulnerabilities, through: :evidences
  has_many :banners, through: :ports

  enum test_status: { not_tested: 10, testing: 20, aborted: 80, tested: 99 }

  validates :ip, presence: true
  validates :ip, uniqueness: { scope: [:site_id] }
  validates :ip, format: { with: Regexp.union(Resolv::IPv4::Regex, Resolv::IPv6::Regex) }

  def tcp
    ports.where(proto: :tcp)
  end

  def udp
    ports.where(proto: :udp)
  end

  def ports_table
    [
      "ip : #{ip}",
      table(tcp, 'tcp ports'),
      table(udp, 'udp ports')
    ].join("\n")
  end

  def table(ports, title)
    t = Terminal::Table.new(title: title, rows: ports.order(:no).map(&:to_a))
    t.headings = %w[no state ssl plain service nmap_service nmap_version]
    t
  end

  private :table

  #
  # Search all hosts's evidences and sort by port no and protocol
  #
  # SELECT evidences.*,
  #        ports.proto,
  #        ports.no,
  # FROM   evidences
  # LEFT JOIN ports ON ports.id = evidences.port_id
  # WHERE evidences.host_id = 10
  # ORDER BY ports.proto ASC NULLS FIRST,
  #          ports.no ASC NULLS FIRST,
  #          evidences.title ASC;
  #
  #
  def evidences_ordered
    e = Evidence.arel_table

    evidences.joins(joins_ports)
             .order(Arel::Nodes::SqlLiteral.new('ports.proto ASC NULLS FIRST'))
             .order(Arel::Nodes::SqlLiteral.new('ports.no ASC NULLS FIRST'))
             .order(e[:title].asc)
  end

  def joins_ports
    p = Port.arel_table
    e = Evidence.arel_table

    e.join(p, Arel::Nodes::OuterJoin).on(e[:port_id].eq(p[:id])).join_sources
  end

  private :joins_ports
end
