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
module TargetCommands
  STRUCTURE = {
    target: {
      method: nil, help: 'manage target hosts',
      children: {
        list:   { method: :target_list, help: 'list target hosts' },
        add:    { method: :target_add,  help: 'add target host' },
        delete: { method: :target_del,  help: 'delete target host' },
        help:   { method: nil,          help: 'show help' },
        exit:   { method: nil,          help: 'exit from target mode' }
      }
    }
  }.freeze

  #
  # show target host list
  #
  def target_list(_, site: nil)
    site ||= @site
    return unless Inspector.site_selected?(site, @console)
    site.reload
    @console.info self, TerminalSupport.table(site.hosts, :ip)
  end

  #
  # add target host
  #
  def target_add(args)
    return unless Inspector.site_selected?(@site, @console)

    ip = Inspector.require_one(args, @console)
    return unless ip

    host = @site.hosts.new(ip: ip)
    unless host.valid?
      @console.error self, host.errors.full_messages.join("\n")
      return
    end

    host.save
    @console.info self, "Added ip address : #{ip}"
  end

  #
  # delete target host
  #
  def target_del(args)
    return unless Inspector.site_selected?(@site, @console)

    host = Selector.from_array(@site.hosts, :ip, args, @console)
    return unless host

    # error if any running tester for selected host
    return if Inspector.running_any?(@testers, @console, host: host)

    # delete host after confirmation
    TargetPrivate.delete_host(@testers, host, @console)
  end

  module TargetPrivate
    def self.confirm_to_delete(host, console)
      console.info self, 'Test result would be deleted.' unless host.test_status == 'not_tested'
      prompt = "Really want to delete target #{host.ip}?"
      Inquiry.confirm(prompt, console)
    end
    private_class_method :confirm_to_delete

    def self.delete_host(testers, host, console)
      if confirm_to_delete(host, console)
        testers.delete_if { |t| t.host == host }
        ip = host.ip
        host.destroy
        console.info self, "Deleted target #{ip} successfully"
      else
        console.info self, 'Canceled to delete the target'
      end
    end
  end
end
