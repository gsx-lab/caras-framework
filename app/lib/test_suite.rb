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
class TestSuite
  attr_reader :root, :individual, :orphan, :name, :top_level, :class_names, :unloaded, :errors

  def initialize(path_to)
    @path_to = path_to
    @errors = []

    resolve_module_top_level_name
    @name = camelize_path(@path_to[:current_test_suite], @path_to[:current_test_suite])
    @root = nil
    @individual = nil
    @orphan = nil
    @class_names = []
    @unloaded = []
  end

  #
  # load all test cases and returns the result
  #
  def load
    result = unload

    @class_names = load_test_cases

    @root = set_root_tree
    @individual = set_individual_tree
    @orphan = set_orphan_tree

    result.merge!(loaded: @class_names, error?: error?)
  end

  #
  # unload all test cases
  #
  def unload
    @errors = []
    TestCase.delete_all
    @unloaded = unload_test_cases
    @class_names = []
    { unloaded: @unloaded, error?: error? }
  end

  #
  # reload is an alias to load
  #
  def reload
    load
  end

  #
  # has any errors?
  #
  def error?
    @errors.length.positive?
  end

  #
  # format result to human readable message
  #
  def result_to_s
    info = []
    info.concat(@unloaded.map { |l| "unloaded : #{l}" }) if @unloaded.length.positive?
    info.concat(@class_names.map { |l| "loaded : #{l}" }) if @class_names.length.positive?

    { info: info.join("\n"), error: @errors.join("\n") }
  end

  private

  def resolve_module_top_level_name
    @top_level = @path_to[:test_suites].basename.to_s.camelize
  end

  def camelize_path(test_suite_dir, filename)
    path = Pathname.new(filename).relative_path_from(test_suite_dir.parent)
    module_path = path.dirname.join(path.basename('.rb'))

    components = module_path.each_filename.to_a
    components.map! do |c|
      raise ArgumentError, "#{filename}: Directory or filename must start with alphabet : #{module_path}" if c.match?(/^\d|^_/)
      c.gsub(/[\W]/, '')
    end
    components.join('/').camelize
  end

  def unload_test_cases(current = nil)
    current ||= @top_level
    current_const = get_current_const(current)
    return [] unless current_const

    unloaded = []

    # enumerate constants of current_const
    current_const.constants.each do |const_name|
      constant = constantize(current_const, const_name)
      next unless constant

      # unload child constants before unload current
      if constant.constants.empty?
        unloaded << unload_module(constant)
      else
        unloaded += unload_test_cases(constant.to_s)
      end
    end

    unload_module(current)

    unloaded << current
  end

  def get_current_const(current)
    return nil unless Object.const_defined?(current)
    Object.const_get(current)
  end

  def constantize(current_const, const_name)
    constant_str = [current_const.to_s, const_name.to_s].join('::')
    return nil unless Object.const_defined?(constant_str)
    constant = constant_str.constantize

    return nil unless constant.to_s == constant_str
    constant
  end

  def unload_module(const)
    module_names = const.to_s.split('::')
    constant_name = module_names.pop
    parent_const = module_names.empty? ? Object : Object.const_get(module_names.join('::'))
    parent_const.module_eval { remove_const constant_name.to_sym }
    const.to_s
  end

  def load_test_cases
    files = rb_files_ordered.map do |filename|
      begin
        class_name = camelize_path(@path_to[:test_suites], filename)
        load_test_case(class_name, filename)
      rescue SyntaxError, StandardError => e
        unload_test_cases(class_name) if class_name
        @errors << e.to_s
        next
      end
      class_name
    end
    files.compact
  end

  def rb_files_ordered
    Inspector.glob_except_libs(@path_to[:current_test_suite], '*.rb')
  end

  def load_test_case(class_name, filename)
    # "TestSuites::SuiteName::Path::To::TestCase" to ["TestSuites", "SuiteName", "Path", "To", "TestCase"]
    module_hierarchy = class_name.split('::')

    # get class name
    constant = module_hierarchy.pop

    # load source code
    module_source = File.read(filename)

    # load module to anonymous module for validation
    anon_module = Module.new
    anon_module.module_eval(module_source, filename)
    TestCaseValidator.new(filename, class_name, anon_module, constant).validate

    # create module and load
    create_module(module_hierarchy).module_eval(module_source, filename)
  end

  def create_module(module_hierarchy)
    parent_module = Object
    module_hierarchy.each do |module_name|
      # next if already defined
      if parent_module.const_defined? module_name
        parent_module = parent_module.const_get(module_name)
        next
      end

      # define new if undefined
      m = Module.new
      parent_module = parent_module.const_set(module_name.to_sym, m)
    end
    parent_module
  end

  class TestCaseValidator
    class MalformedTestCaseException < StandardError
    end

    def initialize(filename, class_name, parent_module, constant)
      @filename = filename
      @class_name = class_name
      @parent_module = parent_module
      @constant = constant
    end

    def validate
      reserved?
      contains?
      @clazz = @parent_module.const_get(@constant)
      inherit_template?
      valid_methods_defined?
    end

    private

    # has reserved namespace?
    def reserved?
      raise MalformedTestCaseException, "#{@filename}: #{@constant} has reserved namespace." if ['Individual'].include?(@class_name.split('::')[2])
    end

    # defined expected constant?
    def contains?
      raise MalformedTestCaseException, "#{@filename}: must be contain class #{@constant}." unless @parent_module.const_defined? @constant
    end

    # inherit TestCaseTemplate?
    def inherit_template?
      raise MalformedTestCaseException, "#{@filename}: #{@constant} does not inherit class TestCaseTemplate." unless @clazz < TestCaseTemplate
    end

    # attack || target_ports && attack_on_port defined?
    def valid_methods_defined?
      if @clazz.method_defined? :attack
        # if attack defined, target_ports or attack_on_port should not be defined
        if @clazz.method_defined?(:target_ports) || @clazz.method_defined?(:attack_on_port)
          raise MalformedTestCaseException, "#{@filename}: #{@constant}#attack defined but #target_ports or #attack_on_port are also defined."
        end
      else
        # if attack not defined, target_ports and attack_on_port should be defined
        unless @clazz.method_defined?(:target_ports) && @clazz.method_defined?(:attack_on_port)
          raise MalformedTestCaseException, "#{@filename}: #{@constant}#attack is not defined, #target_ports nor #attack_on_port are also not defined."
        end
      end
    end
  end

  def set_root_tree
    root_tree =
      TestCase.create(
        name: 'root',
        dangles: :tree,
        root: true,
        description: 'root of test suite tree'
      )
    set_tree root_tree, nil
    root_tree.reload
    root_tree
  end

  def set_individual_tree
    individual_tree =
      TestCase.create(
        name: 'individual',
        dangles: :individual,
        root: true,
        description: 'individual test cases'
      )
    set_tree individual_tree, 'Individual'
    individual_tree.reload
    individual_tree
  end

  def set_orphan_tree
    orphan_tree =
      TestCase.create(
        name: 'orphan',
        dangles: :orphan,
        root: true,
        description: 'orphan test cases'
      )
    adopt_orphans orphan_tree
    orphan_tree.reload
    orphan_tree
  end

  def find_children_of(parent)
    @class_names.select do |class_name|
      c = Module.const_get(class_name)
      resolve_requirement(c) == parent
    end
  end

  def resolve_requirement(test_case_constant)
    if test_case_constant.requires.nil? || test_case_constant.requires == 'Individual'
      return test_case_constant.requires
    end

    [@top_level, @name, test_case_constant.requires].join('::')
  end

  def set_tree(node, parent)
    find_children_of(parent).each do |class_name|
      c = Module.const_get(class_name)
      requires = resolve_requirement(c)
      node.create_child(class_name, c, requires)
    end
    node.children.each do |child|
      set_tree(child, child.name) unless find_children_of(child.name).empty?
    end
  end

  def adopt_orphans(node)
    all_classes = TestCase.select(:name).map(&:name)
    (@class_names - all_classes).each do |class_name|
      c = Module.const_get(class_name)
      requires = resolve_requirement(c)
      node.create_child(class_name, c, requires)
    end
  end
end
