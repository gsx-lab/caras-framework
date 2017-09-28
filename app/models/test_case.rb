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
class TestCase < ApplicationRecord
  has_many :children, class_name: 'TestCase', foreign_key: :parent_id
  belongs_to :parent, class_name: 'TestCase', foreign_key: :parent_id

  enum dangles: { tree: 10, individual: 20, orphan: 99 }

  #
  # show dependency tree
  #
  def show_tree(running: nil, finished: nil)
    get_tree_list(0, [], running, finished).map { |line| ' ' + line }.join("\n")
  end

  def branch(index, prefix, depth, running = nil, finished = nil)
    lines = []
    prefix[-1] = siblings.length == index ? '`--' : '|--'
    lines << prefix.join + decorate_name(running, finished)
    if parent?
      prefix[-1] = siblings.length > index ? '|  ' : '   '
      lines.concat get_tree_list(depth + 1, prefix, running, finished)
    end
    lines
  end

  #
  # returns all descendants array
  #
  def descendants
    desc = []
    children.each do |tc|
      desc << tc
      desc += tc.descendants if tc.parent?
    end
    desc
  end

  #
  # returns all descendants class names array
  #
  def class_names
    descendants.map(&:name)
  end

  #
  # show all descendants information
  #
  def show_all_children_info
    descendants.map(&:to_s)
  end

  #
  # TestCase info
  #
  def to_s
    rows = [
      ['description', description],
      ['protocol', protocol],
      ['requires', requires],
      ['dangles', dangles],
      ['author', author]
    ]
    table = Terminal::Table.new(rows: rows)
    table.style = { border_top: false, border_bottom: false, border_y: '' }
    [name, table.to_s].join("\n")
  end

  #
  # class of this test case
  #
  def clazz
    Module.const_get(name)
  rescue NameError
    nil
  end

  #
  # create child of this test case
  #
  def create_child(child_name, constant, requires)
    TestCase.create(
      parent_id: id,
      root: false,
      dangles: dangles,
      name: child_name,
      requires: requires,
      runs_per_port: constant.method_defined?(:attack_on_port),
      protocol: constant.protocol,
      description: constant.description,
      author: constant.author
    )
  end

  #
  # has any children? if so, you are parent.
  #
  def parent?
    !children.empty?
  end

  #
  # array of brothers and sisters
  #
  def siblings
    parent&.children || []
  end

  #
  # instantiate this test case class
  #
  def instantiate(*args)
    clazz.new(*args)
  end

  private

  def get_tree_list(depth, prefix, running = nil, finished = nil)
    lines = []
    prefix.push('')

    if depth.zero?
      lines << name
      depth += 1
    end

    children.each.with_index(1) do |child, index|
      lines.concat child.branch(index, prefix, depth, running, finished)
    end

    prefix.pop
    lines
  end

  def decorate_name(running = nil, finished = nil)
    if running&.include?(name)
      Console::TextAttr::UNDERLINED + 'run ' + name + Console::TextAttr::RESET_UNDERLINED
    elsif finished&.include?(name)
      Console::TextAttr::DIM + 'fin ' + name + Console::TextAttr::RESET_DIM
    else
      name
    end
  end
end
