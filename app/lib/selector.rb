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
module Selector
  def self.from_array(array, column, args, console = nil, name: nil)
    arg = Inspector.require_one(args, console)
    return nil unless arg

    number = a_number(args)

    item = nil
    item = find_by_number(array, number) if number
    item = find_by_column(array, column, arg) unless item

    console&.error self, "#{arg} is not valid number nor in the #{name_of(array, name)}." unless item
    item
  end

  def self.a_number(args, console = nil, to_be_positive: true)
    str = Inspector.require_one(args, console)
    return nil unless str
    return nil unless Inspector.integer?(str, console)

    number = str.to_i
    if to_be_positive && !number.positive?
      console&.warn self, 'number must be positive'
      return nil
    end
    number
  end

  def self.name_of(array, name)
    return name if name
    return array.model.name.pluralize if array.is_a? ActiveRecord::Relation
    'list'
  end

  private_class_method :name_of

  def self.find_by_number(array, number)
    if array.is_a? ActiveRecord::Relation
      array.offset(number - 1).limit(1).first
    else
      array[number - 1]
    end
  end

  private_class_method :find_by_number

  def self.find_by_column(array, column, name)
    if array.is_a? ActiveRecord::Relation
      array.find_by(column => name)
    else
      array.find { |item| item[column] == name }
    end
  end

  private_class_method :find_by_column
end
