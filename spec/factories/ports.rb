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
FactoryGirl.define do
  factory :port, class: 'Port' do
    no 1
    proto :tcp

    trait :http do
      no 80
      proto :tcp
      nmap_service 'http nmap'
      service 'http'
    end

    trait :smtp do
      no 25
      proto :tcp
      nmap_service 'smtp nmap'
      service 'smtp'
    end

    trait :open do
      no 2
      proto :tcp
      state :open
    end

    trait :closed do
      no 3
      proto :tcp
      state :closed
    end

    trait :plain do
      no 4
      proto :tcp
      plain true
    end

    trait :ssl do
      no 5
      proto :tcp
      ssl true
    end

    trait :udp do
      no 6
      proto :udp
    end

    trait :tcp do
      no 7
      proto :tcp
    end
  end
end
