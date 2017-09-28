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
module Inspector
  #
  # one argument must be required
  #
  def self.require_one(args, console = nil)
    if args.length != 1
      console&.error self, 'one parameter is required'
      return nil
    end
    args[0]
  end

  #
  # check if the string would be a number
  #
  def self.integer?(str, console = nil)
    Integer(str)
    true
  rescue ArgumentError
    console&.warn self, "#{str} is not a number"
    false
  end

  #
  # return true if there is any running testers.
  #
  def self.running_any?(testers, console = nil, host: nil)
    testers = running_testers(testers, host)
    if !testers.empty?
      console&.warn self, 'Some tests are running. View status for description.'
      true
    else
      false
    end
  end

  #
  # select running testers
  #
  def self.running_testers(testers, host = nil)
    running = testers.select(&:running?)
    running = running.select { |t| t.host == host } if host
    running
  end

  private_class_method :running_testers

  #
  # return true if site is selected
  #
  def self.site_selected?(site, console = nil)
    if site
      true
    else
      console&.warn self, 'Select site first'
      false
    end
  end

  #
  # return true if site has any targets
  #
  def self.targets?(site, console = nil)
    if Host.where(site: site).exists?
      true
    else
      console&.warn self, 'Add target first'
      false
    end
  end

  #
  # enumerate files except libs
  #  dir : array of directories(Pathname)
  #  ext : target extension
  def self.glob_except_libs(dirs, ext)
    dirs = [dirs] unless dirs.is_a? Array
    all = dirs.map do |dir|
      Dir.glob(dir.join('**', ext)).reject do |filename|
        Pathname(filename).relative_path_from(dir).each_filename.find { |fn| fn == 'lib' }
      end
    end
    all.flatten.sort
  end
end
