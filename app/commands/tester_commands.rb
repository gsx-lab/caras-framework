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
module TesterCommands
  STRUCTURE = {
    attack: { method: :tester_attack, help: 'start attack' },
    status: { method: :tester_status, help: 'show Tester\'s status' },
    stop:   { method: :tester_stop,   help: 'stop running testers' }
  }.freeze

  #
  # start to attack
  #
  def tester_attack(_)
    return unless Inspector.site_selected?(@site, @console)
    return unless Inspector.targets?(@site, @console)
    return if Inspector.running_any?(@testers, @console)

    @site.reload
    tr = TesterRunner.new(@site, @console, @testers)
    tr.create_testers(@path_to, @test_suite.root, @thread_manager, @site_mutex)
    tr.run
  rescue StandardError => e
    @console.fatal self, e
  end

  #
  # show testers' statistics
  #
  def tester_status(_)
    status = @testers.select { |t| t.site == @site }.map(&:status).join("\n")

    messages = [
      status,
      "Queued  testers : #{@thread_manager.queued}",
      "Running testers : #{@thread_manager.running}/#{@thread_manager.max}",
      "Waiting testers : #{@thread_manager.waiting}",
      "All threads     : #{Thread.list.count}"
    ].reject(&:empty?).join("\n")

    @console.info self, messages
  end

  #
  # stop tester
  #
  def tester_stop(_)
    if @testers.find(&:running?)
      prompt = 'Tester is running. Do you still want to stop?'
      return unless Inquiry.confirm(prompt, @console)

      @console.info self, 'Shutting down.'
      @testers.each do |tester|
        begin
          tester.shutdown
        rescue StandardError => e
          @console.fatal self, e
        end
      end
    end
    true
  end

  class TesterRunner
    def initialize(site, console, all_testers)
      @site = site
      @console = console
      @all_testers = all_testers
    end

    def create_testers(path_to, test_node, thread_manager, site_mutex)
      @current_testers = @site.hosts.map do |host|
        create_tester(host, path_to, test_node, thread_manager, site_mutex)
      end
    end

    def run
      @site.update(attack_started: Time.now)
      Thread.fork(@site) do |site|
        begin
          tester_threads.each(&:join)
        ensure
          @console.info self, 'Done all tests', force_to_console: true
          site.reload
          site.update(attack_finished: Time.now)
        end
      end
    end

    private

    def create_tester(host, path_to, test_node, thread_manager, site_mutex)
      unless host.test_status == 'not_tested'
        return nil unless really_want_to_rerun?(host)
        destroy_evidences(host, test_node.class_names)
      end

      tester = Tester.new(
        host: host,
        path_to: path_to,
        console: @console,
        test_node: test_node,
        thread_manager: thread_manager,
        site_mutex: site_mutex
      )

      @all_testers.delete_if { |t| t.host == host }
      @all_testers.push(tester)
      tester
    end

    def really_want_to_rerun?(host)
      @console.info self, "Test result of #{host.ip} created by current test suite would be destroyed."
      prompt = 'Really want to rerun?'
      Inquiry.confirm(prompt, @console)
    end

    def destroy_evidences(host, class_names)
      host.reload
      host.evidences.where(title: class_names).destroy_all
      host.banners.where(detected_by: class_names).destroy_all
    end

    def tester_threads
      @current_testers.map do |tester|
        Thread.fork do
          @console.info self, "Start tester for #{tester.ip}", force_to_console: true
          tester.run
          @console.info self, "Done tests for #{tester.ip}", force_to_console: true
        end
      end
    end
  end
end
