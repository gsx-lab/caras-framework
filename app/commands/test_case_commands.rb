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
module TestCaseCommands
  STRUCTURE = {
    testcase: {
      method: nil, help: 'manage test cases',
      children: {
        tree: { method: :test_case_tree, help: 'show test case tree' },
        info: { method: :test_case_info, help: 'show description of test cases' },
        new:  { method: :test_case_new,  help: 'create new test case template' },
        run:  { method: :test_case_run,  help: 'run test case individually' },
        help: { method: nil,             help: 'show help' },
        exit: { method: nil,             help: 'exit from testcase mode' }
      }
    }
  }.freeze

  #
  # show test case tree
  #
  def test_case_tree(_)
    @console.info self, ['TestSuite tree : ',        @test_suite.root.show_tree].join("\n")
    @console.info self, ['Individual test cases : ', @test_suite.individual.show_tree].join("\n")
    @console.warn self, ['Orphan test cases : ',     @test_suite.orphan.show_tree].join("\n")
  end

  #
  # show test case information
  #
  def test_case_info(args)
    if args.empty?
      all = [
        @test_suite.root.show_all_children_info,
        @test_suite.individual.show_all_children_info,
        @test_suite.orphan.show_all_children_info
      ].flatten.join("\n\n")
      @console.info self, all
    else
      tc = TestCase.find_by(name: args[0])
      @console.info self, tc.to_s if tc
    end
  end

  #
  # create new test case template
  #
  def test_case_new(args)
    path = Inspector.require_one(args, @console)
    return unless path

    test_case = TestCaseGenerator.generate(path, @path_to, @console)
    return unless test_case

    path = @path_to[:current_test_suite].join(test_case[:path])
    FileUtils.mkdir_p(path.dirname) unless File.directory?(path.dirname)
    File.write(path, test_case[:code])
    @console.info self, "new test case is generated in #{path}"
  end

  #
  # Run test case individually
  #
  def test_case_run(args)
    return unless Inspector.site_selected?(@site, @console)
    return if Inspector.running_any?(@testers, @console)

    tcr = TestCaseRunner.new(@site, @console, @path_to, @site_mutex, @thread_manager)

    return unless tcr.select_test_case(args)

    return unless tcr.select_host

    return unless tcr.select_port_no

    return unless tcr.continue?

    tcr.run
  rescue Interrupt
    nil
  end

  module TestCaseGenerator
    def self.generate(path, path_to, console)
      path = gain_path(path, path_to, console)
      return nil unless path
      { path: path, code: test_case_template(path) }
    end

    def self.gain_path(path, path_to, console)
      usage = [
        'One test case path must be required.',
        'TestCase path should be like "path/to/test_case.rb".',
        'It must end with ".rb".',
        'New template file will be created in specified path.'
      ].join("\n")

      # compress multiple slashes and delete heading slash
      path.squeeze!('/')
      path.sub!(/^\//, '')

      # example of parameter : path/to/attack.rb
      result = catch :error do
        PathValidator.valid?(path, path_to)
      end

      if result
        console.error self, result
        console.warn self, usage
        return nil
      end

      path
    end

    private_class_method :gain_path

    def self.test_case_template(path)
      name = File.basename path.camelize, '.*'
      clazz_name = name.split('::').pop
      code = <<~ENDOFCODE
        #
        # #{name}
        #
        class #{clazz_name} < TestCaseTemplate
          @description = 'sample description of test #{clazz_name}'

          # Specify parent test case module name like '#{name}'.
          # Other option:
          #   @requires = nil          # has no parent test case, starts first.
          #   @requires = 'Individual' # does not implement test suite tree.
          @requires = nil

          # Specify test target protocol
          @protocol = 'sample protocol'

          # Your name
          @author = ''

          # If this test case runs for one host, implement 'attack' method, and
          # do NOT define 'target_ports' nor 'attack_on_port' methods.
          def attack
            # write your great test off!
          end

          # If this test case runs for every port, implement below methods
          # 'target_ports' and 'attack_on_port', and *DELETE 'attack' method*.
          #
          # target_ports extracts attack target ports
          # @return [ActiveRecord::Relation, Array<Port>]
          # def target_ports
          #   # Example
          #   @host.tcp.service('http')
          # end

          # attack_on_port runs for each port.
          # @param [Port] port target port
          # def attack_on_port(port)
          #   # write your great test off!
          # end
        end
      ENDOFCODE
      code
    end

    private_class_method :test_case_template

    module PathValidator
      def self.valid?(path, path_to)
        valid_extname?(path)
        valid_characters?(path)
        trails_basename?(path)
        valid_underscore_position?(path)
        starts_with_alphabet?(path)
        reserved?(path)
        test_case_exist?(path, path_to)
      end

      def self.valid_extname?(path)
        return if path.end_with? '.rb'
        throw :error, 'path must end with ".rb".'
      end

      private_class_method :valid_extname?

      def self.valid_characters?(path)
        return if path[0..-4].match?(/^[a-z0-9_\/]+$/)
        throw :error, 'invalid character.'
      end

      private_class_method :valid_characters?

      def self.trails_basename?(path)
        return if path[-4].match?(/[a-z0-9]/)
        throw :error, 'basename must be required.'
      end

      private_class_method :trails_basename?

      def self.valid_underscore_position?(path)
        return unless path[0..-4].split('/').find { |s| s.start_with?('_') || s.end_with?('_') }
        throw :error, 'underscore must be between alphabets/numbers.'
      end

      private_class_method :valid_underscore_position?

      def self.starts_with_alphabet?(path)
        return unless path[0..-4].split('/').find { |s| s.match?(/^[^a-z]/) }
        throw :error, 'each directory or basename must start with alphabet.'
      end

      private_class_method :starts_with_alphabet?

      def self.reserved?(path)
        return unless ['individual.rb'].include?(path)
        throw :error, 'reserved.'
      end

      private_class_method :reserved?

      def self.test_case_exist?(path, path_to)
        return unless path_to[:current_test_suite].join(path).exist?
        throw :error, 'already exists.'
      end

      private_class_method :test_case_exist?
    end
  end

  class TestCaseRunner
    def initialize(site, console, path_to, site_mutex, thread_manager)
      @site = site
      @console = console
      @path_to = path_to
      @site_mutex = site_mutex
      @thread_manager = thread_manager
    end

    def select_test_case(args)
      test_cases = TestCase.where(root: false)

      test_case_name = args.shift
      if test_case_name
        test_case = test_cases.find_by(name: test_case_name)
        unless test_case
          @console.error self, "No test case named as #{test_case_name}"
          return false
        end
      else
        lead = 'Select test case number to run or "x" to exit'
        question = 'Which do you want to run?'
        test_case = Inquiry.number_from_records(lead, question, test_cases, :name, @console)
        return false if test_case == :exit
      end
      @test_case = test_case
      true
    end

    def select_host
      hosts = @site.hosts
      lead = 'Select target host to test or "x" to exit'
      question = 'Which do you want to test?'
      host = Inquiry.number_from_records(lead, question, hosts, :ip, @console)
      return false if host == :exit
      @host = host
      true
    end

    def select_port_no
      return true unless @test_case.runs_per_port

      question = "Select target port number or 0 to leave it to test case's choice."
      port_no = nil
      loop do
        port_no = Inquiry.number_from_range(question, 0, 65535, @console)
        return false if port_no == :exit
        break unless %i[malformed_format out_of_range].include?(port_no)
      end
      @port_no = port_no
      true
    end

    def continue?
      target = @port_no&.positive? ? @host.ports.find_by(no: @port_no) : @host

      # continue if the host does not have port specified number
      return true unless target

      evidences = evidences_of(target)
      banners = banners_of(target)

      return false unless destroy_evidences?(target, evidences, banners)

      evidences.destroy_all unless evidences.empty?
      banners.destroy_all unless banners.empty?

      true
    end

    def run
      # force to display sub thread message
      old_show_thread_message_flg = @console.show_thread_message
      @console.show_thread_message = true

      run_test_case(instantiate)

      @console.show_thread_message = old_show_thread_message_flg
    end

    private

    def destroy_evidences?(target, evidences, banners)
      return true if evidences.empty? && banners.empty?

      message, prompt = message_for_destroy(target, evidences, banners)
      @console.info self, message
      Inquiry.confirm(prompt, @console)
    end

    def evidences_of(target)
      target.evidences.where(title: @test_case.name)
    end

    def banners_of(target)
      target.banners.where(detected_by: @test_case.name)
    end

    def message_for_destroy(target, evidences, banners)
      lines = []
      lines << "#{evidences.length} test evidences" unless evidences.empty?
      lines << "#{banners.length} banners" unless banners.empty?
      message = [
        lines.join(' and '),
        " of #{@test_case.name} for ",
        target.is_a?(Host) ? target.ip : "#{target.host.ip}:#{target.no}",
        ' would be destroyed.'
      ].join
      prompt = 'Really want to run?'
      [message, prompt]
    end

    def instantiate
      data_dir = @path_to[:data].join(@site.name).join(@host.ip).join(@test_case.clazz.dir)
      ins = @test_case.instantiate(@host, data_dir, @path_to, @console, @site_mutex)
      @console.info self, "#{@test_case.name} instantiated"
      ins
    end

    def run_test_case(ins)
      @console.info self, "#{@test_case.name} start"
      instance_thread = Thread.fork do
        ins.run(@thread_manager, @port_no)
      end
      instance_thread.join
    rescue Interrupt => _e
      instance_thread.kill
      @console.error self, "#{@test_case.name} interrupted"
    rescue StandardError => e
      @console.error self, "#{@test_case.name} runtime error"
      @console.fatal self, e
    ensure
      @console.info self, "#{@test_case.name} end"
    end
  end
end
