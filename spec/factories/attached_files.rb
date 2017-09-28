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
  factory :attached_file, class: 'AttachedFile' do
    trait :png do
      filename 'png'
      file { File.binread(CarashEnvironment.path_to[:base].join('spec', 'fixtures', 'attached_files', 'png')) }
    end

    trait :text do
      filename 'text'
      file { File.binread(CarashEnvironment.path_to[:base].join('spec', 'fixtures', 'attached_files', 'text')) }
    end

    trait :binary do
      filename 'binary'
      file { File.binread(CarashEnvironment.path_to[:base].join('spec', 'fixtures', 'attached_files', 'binary')) }
    end
  end
end
