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
require 'fileutils'
require 'active_support'
require 'active_support/core_ext'

class Tester
  attr_reader :host, :ip, :site, :name, :instances

  def initialize(args)
    initialize_target(args)
    initialize_state
  end

  def running?
    return false unless Host.exists?(@host.id)
    @host.reload
    @host.testing?
  end

  def status
    res = []
    running = @instances.select(&:running?).map(&:name)
    finished = @instances.reject(&:running?).map(&:name)
    all = @test_node.descendants

    res << decorate_status_summary(running.count, finished.count, all.count)

    res << @test_node.show_tree(running: running, finished: finished)
    res.join("\n")
  end

  def run
    if @host.testing?
      @console.err self, "#{@name} is already running"
      return
    end

    begin
      @host.update test_status: :testing

      @console.info self, "#{@name} start running"

      @threads = []
      @instances = []
      run_tree

      @threads.each(&:join)
    ensure
      @console.info self, "#{@name} finished running" unless @shutting_down
      @host.update test_status: :tested
    end
  end

  def shutdown
    @shutting_down = true
    @instances.each do |ins|
      ins.abort if ins.running?
    end
    @threads.each(&:kill)
    @host.update(test_status: :aborted) if @host.test_status == :testing
    @shutting_down = false
  end

  private

  def initialize_target(args)
    @host = args[:host]
    @console = args[:console]
    @thread_manager = args[:thread_manager]
    @site_mutex = args[:site_mutex]
    @path_to = args[:path_to]
    @test_node = args[:test_node]
    @ip = @host.ip
    @site = @host.site
  end

  def initialize_state
    @name = "Tester:#{ip}@#{site.name}"
    @instances = []
    @shutting_down = false
  end

  def decorate_status_summary(running, finished, all)
    @name + ' => running: [ ' +
      [
        (all - running - finished).to_s,
        Console::TextAttr::UNDERLINED + running.to_s + Console::TextAttr::RESET_UNDERLINED,
        Console::TextAttr::DIM + finished.to_s + Console::TextAttr::RESET_DIM
      ].join(' > ') + ' ]'
  end

  def run_tree(node = @test_node)
    node.children.each do |test_case|
      break if @shutting_down

      t = Thread.fork do
        run_test(test_case)
      end

      @threads << t

      next unless test_case.parent?

      # if this test_case has child test_cases
      c = Thread.fork do
        # wait parent thread
        t.join
        run_tree(test_case)
      end
      @threads << c
    end
  end

  def test_case_dir(host_dir, test_case)
    host_dir.join(test_case.clazz.dir)
  end

  def make_host_dir
    host_dir = @path_to[:data].join(@site.name).join(@ip.to_s)
    host_dir.mkpath unless host_dir.directory?
    host_dir
  end

  def instantiate(test_case, data_dir, message_prefix)
    ins = test_case.instantiate(@host, data_dir, @path_to, @console, @site_mutex)
    @instances << ins
    @console.info self, "#{message_prefix} instantiated"
    ins
  rescue StandardError => e
    @console.error self, "#{message_prefix} instantiate error"
    @console.fatal self, e
    nil
  end

  def run_test(test_case)
    message_prefix = "#{test_case.name} for #{@ip}"
    begin
      host_dir = make_host_dir
      data_dir = test_case_dir(host_dir, test_case)
      ins = instantiate(test_case, data_dir, message_prefix)
      ins&.run(@thread_manager)
    rescue StandardError => e
      @console.error self, "#{message_prefix} runtime error"
      @console.fatal self, e
    ensure
      @console.info self, "#{message_prefix} end"
    end
  end
end
