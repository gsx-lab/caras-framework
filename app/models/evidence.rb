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
class Evidence < ApplicationRecord
  belongs_to :site, required: false
  belongs_to :host, required: false
  belongs_to :port, required: false
  belongs_to :vulnerability, required: false

  has_many :attached_files, dependent: :destroy

  validates :title, presence: true
  validates :host_or_port, presence: true

  before_validation :set_default_keys
  after_update :destroy_orphan_vulnerabilities
  after_destroy :destroy_orphan_vulnerabilities

  def host_or_port
    host.presence || port.presence
  end

  private

  def set_default_keys
    # permitted to update or create without set site_id
    self.site_id = host.site.id if host

    # permitted to update or create without set host_id if port is set
    return unless port
    self.host_id = port.host.id
    self.site_id = port.host.site.id
  end

  def destroy_orphan_vulnerabilities
    # Destroy vulnerabilities when id changed or evidences are destroyed.
    # Extract all vulnerabilities not referred by site
    #
    # SELECT "vulnerabilities".*
    # FROM "vulnerabilities"
    # WHERE "vulnerabilities"."site_id" = <site_id>
    #   AND "vulnerabilities"."id" NOT IN (
    #     SELECT DISTINCT "evidences"."vulnerability_id"
    #     FROM "evidences"
    #     WHERE "evidences"."site_id" = <site_id>
    #       AND "evidences"."vulnerability_id" IS NOT NULL
    # )
    site.vulnerabilities.where.not(
      id: site.evidences
            .select(:vulnerability_id)
            .where.not(vulnerability_id: nil)
            .distinct(:vulnerability_id)
    ).destroy_all
  end
end
