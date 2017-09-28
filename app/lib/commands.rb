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
class Commands
  include Enumerable

  class MalformedCommandException < StandardError
  end

  #
  # load all commands and build commands class
  #
  def self.load_commands(controller, paths)
    structure = {}
    # enumerate files to load
    filenames = Inspector.glob_except_libs(paths, '*.rb')

    filenames.each do |filename|
      # determine module name
      module_name = File.basename(filename, '.*').camelize

      # validate command
      new_structure = valid_command?(filename, module_name)

      # load to controller
      load_command(controller, module_name, filename)
      structure.merge!(new_structure)
    end

    generate_commands(controller, structure)
  end

  #
  # validate command module
  #
  def self.valid_command?(filename, module_name)
    # load test case into anonymous module for validation
    anon_module = load_to_anon_module(Module.new, filename)

    # does expected module define?
    unless anon_module.const_defined? module_name
      raise MalformedCommandException, "module #{module_name} must be defined."
    end

    # defined 'STRUCTURE'?
    mod = anon_module.const_get(module_name)
    unless mod.const_defined? 'STRUCTURE'
      raise MalformedCommandException, "constant STRUCTURE must be defined in #{module_name}."
    end

    # method_names in the STRUCTURE are really defined in the module?
    structure = mod.const_get(:STRUCTURE)
    method_names = enumerate_method_names(structure)
    method_names.each do |method_name|
      unless mod.method_defined? method_name
        raise MalformedCommandException, "#{method_name} is not defined in #{module_name}"
      end
    end
    structure
  end

  private_class_method :valid_command?

  def self.load_to_anon_module(anon_module, filename)
    module_source = File.read(filename)
    anon_module.module_eval(module_source, filename)
    anon_module
  end

  private_class_method :load_to_anon_module

  #
  # enumerate method names from command structure
  #
  def self.enumerate_method_names(structure)
    method_names = []
    structure.each do |_key, definition|
      method_names << definition[:method] if definition[:method]
      method_names.concat enumerate_method_names(definition[:children]) if definition[:children]
    end
    method_names
  end

  private_class_method :enumerate_method_names

  #
  # load a module to controller
  #
  def self.load_command(controller, module_name, filename)
    require filename
    controller.class.include(module_name.constantize)
  end

  private_class_method :load_command

  #
  # generate command structure
  #
  def self.generate_commands(controller, structure, commands = nil, parent = nil)
    commands ||= Commands.new

    structure.each do |name, definition|
      defined_method = definition[:method] ? controller.method(definition[:method]) : nil
      cmd = commands.add(name.to_s, defined_method, definition[:help], parent)
      if definition[:children]
        generate_commands(controller, definition[:children], cmd.children, cmd)
      end
    end
    commands
  end

  private_class_method :generate_commands

  class Command
    attr_reader :name, :method, :description, :children, :parent

    def initialize(name, method, description, parent)
      @name = name
      @method = method
      @description = description
      @children = Commands.new
      @parent = parent
    end

    def parent?
      @children.length.positive?
    end
  end

  def initialize
    @commands = []
  end

  def add(name, method, description, parent)
    cmd = Command.new(name, method, description, parent)
    @commands << cmd
    cmd
  end

  def exists?(name)
    return true if find { |c| c.name == name }
    false
  end

  def description(name)
    find { |c| c.name == name }.description
  end

  def each
    @commands.each do |cmd|
      yield cmd
    end
  end

  def names
    list = []
    @commands.each { |cmd| list << cmd.name }
    list
  end

  def length
    @commands.length
  end

  # search command structure for args
  def recursive_search(args)
    name = args.shift
    cmd = find { |c| c.name == name }
    return cmd, args unless cmd&.parent? && cmd.children.find { |c| c.name == args[0] }

    # the command exists &&
    # the command has sub command &&
    # argument matches sub command name
    # -> should search more
    cmd.children.recursive_search(args)
  end
end
