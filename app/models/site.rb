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
class Site < ApplicationRecord
  default_scope -> { order(:id) }
  has_many :hosts, dependent: :destroy
  has_many :evidences, dependent: :destroy
  has_many :vulnerabilities, dependent: :destroy

  validates :name, format: { with: /\A[[:alnum:]_\-#$]+\z/ }

  def dir(path_to)
    path_to[:data].join(name)
  end
end
