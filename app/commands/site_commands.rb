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
module SiteCommands
  STRUCTURE = {
    site: {
      method: nil, help: 'manage site',
      children: {
        list:   { method: :site_list,   help: 'list of site' },
        select: { method: :site_select, help: 'select site' },
        new:    { method: :site_new,    help: 'create new site' },
        delete: { method: :site_delete, help: 'delete old site' },
        help:   { method: nil,          help: 'show help' },
        exit:   { method: nil,          help: 'exit from site mode' }
      }
    }
  }.freeze

  #
  # Show sites list
  #
  def site_list(_)
    @console.info self, TerminalSupport.table(Site.all, :name, with_check_sign: true, selected: @site)
  end

  #
  # Select existing site
  #
  def site_select(args)
    return if Inspector.running_any?(@testers, @console)
    target_site = Selector.from_array(Site.all, :name, args, @console)
    return unless target_site

    return unless SitePrivate.make_dir(target_site.dir(@path_to), @console)

    @site = target_site
    @console = SitePrivate.change_console(@site, @console, @env_config, @path_to)
    target_list(nil)
  end

  #
  # create a new site
  #
  def site_new(args)
    return if Inspector.running_any?(@testers, @console)

    name = args.empty? ? Time.now.strftime('%Y%m%d-%H%M%S') : args.shift

    site = SitePrivate.create_new(name, @path_to, @console)
    return unless site
    $stdout.puts "created a new site named #{name}"

    @console = SitePrivate.change_console(site, @console, @env_config, @path_to)
    @site = site
  end

  #
  # delete site
  #   leave directory as it is
  def site_delete(args)
    target_site = Selector.from_array(Site.all, :name, args, @console)
    return unless target_site
    if @site && @site.id == target_site.id
      @console.warn self, 'Cannot delete current target site.'
      return
    end

    target_list(nil, site: target_site)
    @console.info self, "Test result will be deleted except files in #{target_site.dir(@path_to)}."
    prompt = 'Really want to delete this site?'
    return unless Inquiry.confirm(prompt, @console)

    target_site.destroy
  end

  module SitePrivate
    def self.exist?(name, path_to)
      # return true if record or directory exists
      site_dir = path_to[:data].join(name)
      site = Site.find_by(name: name)
      site || site_dir.directory? ? true : false
    end

    def self.change_console(site, console, env_config, path_to)
      # do nothing if same as current site
      return console if console.site == site

      # close current console
      console.close(grace: true)

      # determine log path
      log_dir = site.dir(path_to).join('log')
      log_dir.mkpath unless log_dir.exist?
      site_logfile = log_dir.join('controller.log')

      # create a new console
      path_to[:controller_log] = site_logfile
      new_console = Console.new(site_logfile, env_config, site)
      new_console
    end

    def self.make_dir(site_dir, console)
      if site_dir.directory?
        # if writable directory already exists
        return true if site_dir.writable?

        # return nothing if not writable
        console.error self, "You do not have permission to write #{site_dir}."
        return false
      end

      if site_dir.exist?
        # path exists but not directory
        console.error self, "#{site_dir} is not directory."
        return false
      else
        # make directory
        begin
          site_dir.mkpath
        rescue StandardError => e
          console.fatal self, e.to_s
          return false
        end
      end

      true
    end

    def self.create_new(name, path_to, console)
      if Site.exists?(name: name)
        console.error self, "site #{name} already exists."
        return nil
      end

      return nil unless rename_existing_dir(name, path_to, console)

      site = Site.new(name: name)
      unless site.valid?
        console.error self, site.errors.full_messages.join("\n")
        return nil
      end

      return nil unless SitePrivate.make_dir(site.dir(path_to), console)

      site.save
      site
    end

    def self.rename_existing_dir(name, path_to, console)
      site_dir = path_to[:data].join(name)
      return true unless site_dir.exist?

      new_dir = get_new_dir(name, path_to)

      rename(site_dir, new_dir, console)
    end

    private_class_method :rename_existing_dir

    def self.get_new_dir(name, path_to)
      directories = Dir.glob(path_to[:data].join(name + '_*'))
      num = get_max_number(directories)
      path_to[:data].join(name + '_' + num.to_s)
    end

    private_class_method :get_new_dir

    def self.get_max_number(directories)
      num = directories.map { |fn| fn.match(/_([0-9]+)$/) }.compact.max { |m| m[1].to_i }
      num ? num[1].to_i + 1 : 0
    end

    private_class_method :get_max_number

    def self.rename(from, to, console)
      from.rename(to)
      console.info self, from.to_s + ' has been moved to ' + to.to_s
      true
    rescue StandardError => e
      message = [
        e.to_s,
        'Attempting rename existing directory is failed',
        'Operation is canceled'
      ].join("\n")
      console.error self, message
      false
    end

    private_class_method :rename
  end
end
