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
module HostnameCommands
  STRUCTURE = {
    hostname: {
      method: nil, help: 'manage hostname',
      children: {
        list:   { method: :hostname_list,   help: 'list of hostname' },
        add:    { method: :hostname_add,    help: 'add hostname' },
        delete: { method: :hostname_delete, help: 'delete hostname' },
        help:   { method: nil,              help: 'show help' },
        exit:   { method: nil,              help: 'exit from hostname mode' }
      }
    }
  }.freeze

  #
  # show hostname list
  #
  def hostname_list(_)
    return unless Inspector.site_selected?(@site, @console)
    @site.reload
    table = Terminal::Table.new do |t|
      @site.hosts.each do |host|
        t.add_row([host.ip, host.hostnames.map(&:name).join("\n")])
      end
    end

    table.title = 'List of hostnames'
    table.style = { border_top: false, border_x: '', border_y: '', border_i: '' }

    @console.info self, table
  end

  #
  # add hostname to a ip
  #
  def hostname_add(args)
    return unless Inspector.site_selected?(@site, @console)

    params = HostnamePrivate.require_two(args, @console)
    return unless params
    ip = params[0]
    name = params[1]

    host = HostnamePrivate.get_host(@site, ip, @console)
    return unless host

    HostnamePrivate.create_new_hostname(host, name, @console)
  end

  #
  # delete hostname from ip
  #
  def hostname_delete(args)
    return unless Inspector.site_selected?(@site, @console)

    params = HostnamePrivate.require_two(args, @console)
    return unless params
    ip = params[0]
    name = params[1]

    host = HostnamePrivate.get_host(@site, ip, @console)
    return unless host

    HostnamePrivate.destroy_existing_hostname(host, name, @console)
  end

  module HostnamePrivate
    def self.require_two(args, console)
      if args.length != 2
        console.warn self, 'Target ip address and hostname are required'
        return nil
      end
      [args[0], args[1]]
    end

    def self.get_host(site, ip, console)
      host = site.hosts.find_by(ip: ip)
      unless host
        console.warn self, "Target ip address #{ip} does not exist."
        return nil
      end
      host
    end

    def self.create_new_hostname(host, name, console)
      hostname = host.hostnames.new(name: name)
      unless hostname.valid?
        console.warn self, hostname.errors.full_messages.join("\n")
        return
      end

      hostname.save
      console.info self, "Added #{hostname.name} to #{host.ip}"
    end

    def self.destroy_existing_hostname(host, name, console)
      hostname = host.hostnames.find_by(name: name)
      unless hostname
        console.warn self, "#{name} of #{host.ip} does not exist."
        return
      end

      hostname.destroy
      console.info self, "#{name} of #{host.ip} is deleted."
    end
  end
end
