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

class TestCaseCore
  @protocol = ''
  @description = 'this is sample test case description'
  @requires = nil
  @author = ''
  @running = false

  def self.protocol
    @protocol
  end

  def self.author
    @author
  end

  def self.description
    @description.to_s
  end

  def self.requires
    @requires.to_s if @requires
  end

  def self.dir
    Pathname name.gsub('::', '_')
  end

  def initialize(host, data_dir, path_to, console, site_mutex)
    @data_dir = data_dir
    @path_to = path_to
    @host = host
    @site = host.site
    @ip = host.ip
    @console = console
    @site_mutex = site_mutex
    @running = false
    @name = self.class.name
    @processes = []
    @thread_group = ThreadGroup.new
    @mutex = Mutex.new
  end

  def running?
    @running
  end

  def status
    "#{running? ? 'running ' : 'finished'} #{self.class.name}"
  end

  def runs_per_port
    respond_to?(:attack_on_port) && respond_to?(:target_ports)
  end

  # test case runner
  #   actual attack procedure should be wrote on 'attack' or 'attack_on_port' method
  #
  def run(thread_manager, port_no = nil)
    @running = true
    if runs_per_port
      _run_tests_each_ports(thread_manager, port_no)
    else
      _run_tests_on_a_host(thread_manager)
    end
  ensure
    abort
    @running = false
  end

  def abort
    @processes.each do |process|
      Process.kill_tree 'KILL', process.pid if process.alive?
    end
    @thread_group.list.each do |t|
      t.kill if t.alive?
    end
  end

  private

  def _target_service(port_no = nil)
    service_name = @host.ip
    service_name += ":#{port_no}" if port_no
    service_name
  end

  def _on_wait(name, service_name)
    proc do |tm|
      @console.warn self, "#{name} on #{service_name} waiting...(waiting:#{tm.waiting} running:#{tm.running}/#{tm.max})"
    end
  end

  def _after_end(name, service_name)
    proc do |tm|
      @console.info self, "#{name} on #{service_name} end (waiting:#{tm.waiting} running:#{tm.running}/#{tm.max})"
    end
  end

  def _on_start(tm, name, service_name)
    @console.info self, "#{name} on #{service_name} start (waiting:#{tm.waiting} running:#{tm.running}/#{tm.max})"
  end

  def _run_tests_each_ports(thread_manager, port_no)
    ports = target_ports

    if port_no&.positive?
      if ports.is_a? ActiveRecord::Relation
        ports = ports.where(no: port_no)
      elsif ports.is_a? Array
        ports = ports.select { |p| p.no == port_no }
      end
    end

    ports.each do |port|
      _run_tests_on_a_port(thread_manager, port)
    end
    _wait_for_threads(port_no)
  end

  def _run_tests_on_a_port(thread_manager, port)
    service_name = _target_service(port.no)
    t = Thread.fork do
      thread_manager.run_limit(on_wait: _on_wait(@name, service_name), after_end: _after_end(@name, service_name)) do |tm|
        ActiveRecord::Base.connection_pool.with_connection do
          _on_start(tm, @name, service_name)
          attack_on_port(port)
        end
      end
    end
    @thread_group.add t
  end

  def _wait_for_threads(port_no)
    @thread_group.list.each do |t|
      begin
        t.join
      rescue StandardError => e
        @console.error self, "#{@name} on #{_target_service(port_no)} runtime error"
        @console.fatal self, e
      end
    end
  end

  def _run_tests_on_a_host(thread_manager)
    thread_manager.run_limit(on_wait: _on_wait(@name, _target_service)) do |tm|
      ActiveRecord::Base.connection_pool.with_connection do
        _on_start(tm, @name, _target_service)
        attack
      end
    end
  end

  def _before_execute_command(f, cmd)
    begin_time = Time.now
    f.puts("[#{begin_time}] '#{cmd}'")
  end

  def _execute_command(f, cmd, input, ttl)
    Timeout.timeout(ttl) do
      stdin, stdout, stderr, wait_thr = Open3.popen3(_cleared_ruby_env, cmd)
      @processes << wait_thr

      stdin.put input if input
      stdin.close
      out = _puts_each_line(stdout, f)
      err = _puts_each_line(stderr, f)
      { status: wait_thr&.value&.exitstatus, out: out, err: err, timeout: false }
    end
  rescue Timeout::Error
    { status: nil, out: nil, err: nil, timeout: true }
  end

  def _puts_each_line(from, to)
    lines = ''
    from.each do |line|
      to.puts line
      lines += line
    end
    lines
  end

  def _after_execute_command(f, cmd, result)
    end_time = Time.now
    f.puts("[#{end_time}] '#{cmd}' status=#{result[:status]} timeout=#{result[:timeout]}")
  end

  def _cleared_ruby_env
    ruby_related_env = ENV.select { |k, _| k.start_with?('RUBY', 'BUNDLE', 'RBENV') && k != 'RBENV_SHELL' }
    Hash[ruby_related_env.map { |k, _| [k, nil] }]
  end
end
