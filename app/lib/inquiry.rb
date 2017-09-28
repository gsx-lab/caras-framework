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
module Inquiry
  #
  # select a number from range
  # returns a number or error code(:exit, :malformed_format, :out_of_range)
  #
  def self.number_from_range(question, min, max, console)
    prompt = "#{question} [#{min}#{min < max ? " - #{max}" : nil}] "
    response = console.readline(prompt, add_history: false)
    return :exit if response[:words][0] == 'x'

    number = Selector.a_number(response[:words], console, to_be_positive: false)
    return :malformed_format unless number

    if number < min || max < number
      console.warn self, 'Out of range'
      return :out_of_range
    end

    number
  end

  #
  # select from records
  # returns a model or error code(:exit)
  #
  def self.number_from_records(lead, question, records, column, console)
    records.reload
    lead = [lead, TerminalSupport.table(records, column).to_s].join("\n")
    loop do
      console.info self, lead
      selection = Inquiry.number_from_range(question, 1, records.length, console)

      next if %i[malformed_format out_of_range].include?(selection)
      break selection if selection == :exit

      record = records.offset(selection - 1).limit(1).first
      break record if record
    end
  end

  #
  # confirm y or other
  #
  def self.confirm(prompt, console)
    prompt += ' [Y/n] > '
    response = console.readline(prompt, add_history: false)
    response[:words][0].downcase.match?(/^y$/)
  end
end
