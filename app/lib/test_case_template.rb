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
require 'open3'
require 'active_support'
require 'active_support/core_ext'
require 'timeout'
require_relative 'test_case_core.rb'

class TestCaseTemplate < TestCaseCore
  attr_reader :data_dir, :ip, :name
  attr_accessor :port_no, :processes, :running

  #----------------------------------------------------------------------------
  # Methods to be implemented in each TestCases.

  # attack method for a Host
  # def attack
  # end

  # target_ports extracts attack target ports
  # @return [ActiveRecord::Relation, Array<Port>]
  # def target_ports
  # end

  # attack_on_port
  # @param [Port] port target port
  # def attack_on_port(port)
  # end

  private

  #----------------------------------------------------------------------------
  # Helper methods

  # Create new evidence for target
  #
  # @param [Host | Port] target target host or port
  # @param [*] args attributes to create a new evidence
  # @return [Evidence] Instance of Evidence model
  def create_evidence(target, *args)
    params = args.extract_options!.merge(title: @name)
    target.evidences.create(params)
  end

  # Create a new banner for the port if not exists
  #
  # @param [Port] port target port
  # @param [String] banner service banner
  # @return [Banner] Instance of Banner model
  def register_banner(port, banner)
    @site_mutex.synchronize do
      unless port.banners.exists?(info: banner)
        port.banners.create(info: banner, detected_by: @name)
      end
    end
  end

  # Create or update vulnerability
  #
  # @param [Evidence] evidence vulnerability evidence
  # @param [*] args attributes to create a new vulnerability
  # @return [Vulnerability] Instance of Vulnerability model
  def register_vulnerability(evidence, *args)
    @site_mutex.synchronize do
      ActiveRecord::Base.transaction do
        vulnerability = @site.vulnerabilities.find_or_create_by(*args)
        evidence.update(vulnerability: vulnerability)
      end
    end
    evidence.vulnerability
  end

  # Execute command and write stdout/stderr to file
  #
  # @example Returns a Hash as described below
  #   result = command('command', 'filename')
  #   result[:out]     # => [String, nil]  : stdout(nil if timed out)
  #   result[:err]     # => [String, nil]  : stderr(nil if timed out)
  #   result[:status]  # => [Integer, nil] : exit status(nil if timed out)
  #   result[:timeout] # => [Boolean]      : timed out or not
  #
  # @param [String] cmd command to execute
  # @param [String] file filename for logging
  # @param ttl: [Integer] time to live
  # @param input: [String] String for stdout
  # @param append: [Boolean] open mode of log file
  # @return [Hash]
  def command(cmd, file, ttl: 30, input: nil, append: false)
    file = @data_dir.join(file)
    FileUtils.mkdir_p(file.dirname) unless File.directory?(file.dirname)

    mode = append ? 'a' : 'w'
    result = {}

    File.open(file, mode) do |f|
      begin
        f.flock(File::LOCK_EX)
        _before_execute_command(f, cmd)
        result = _execute_command(f, cmd, input, ttl)
        _after_execute_command(f, cmd, result)
      ensure
        f.flock(File::LOCK_UN)
      end
    end
    result
  end
end
