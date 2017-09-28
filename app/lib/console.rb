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
require 'mutex_m'
require 'thread'
require 'logger'

class Console
  include Mutex_m
  module TextAttr
    RESET      = "\e[0m".freeze
    BOLD       = "\e[1m".freeze
    DIM        = "\e[2m".freeze
    UNDERLINED = "\e[4m".freeze
    BLINK      = "\e[5m".freeze
    REVERSE    = "\e[7m".freeze
    CONCEAL    = "\e[8m".freeze
    RESET_BOLD       = "\e[21m".freeze
    RESET_DIM        = "\e[22m".freeze
    RESET_UNDERLINED = "\e[24m".freeze
    RESET_BLINK      = "\e[25m".freeze
    RESET_REVERSE    = "\e[27m".freeze
    RESET_CONCEAL    = "\e[28m".freeze
  end
  module ForeColor
    RESET   = "\e[0m".freeze
    BLACK   = "\e[30m".freeze
    RED     = "\e[31m".freeze
    GREEN   = "\e[32m".freeze
    YELLOW  = "\e[33m".freeze
    BLUE    = "\e[34m".freeze
    MAGENTA = "\e[35m".freeze
    CYAN    = "\e[36m".freeze
    WHITE   = "\e[37m".freeze
  end
  module BackColor
    RESET   = "\e[0m".freeze
    BLACK   = "\e[40m".freeze
    RED     = "\e[41m".freeze
    GREEN   = "\e[42m".freeze
    YELLOW  = "\e[43m".freeze
    BLUE    = "\e[44m".freeze
    MAGENTA = "\e[45m".freeze
    CYAN    = "\e[46m".freeze
    WHITE   = "\e[47m".freeze
  end

  LEVELS = %i[debug info warn error fatal].freeze
  SHIFT_AGES = %w[daily weekly monthly].freeze

  COLOR = {
    debug: nil,
    info: ForeColor::CYAN,
    warn: ForeColor::MAGENTA,
    error: ForeColor::RED,
    fatal: ForeColor::RED
  }.freeze

  SEVERITY = {
    debug: Logger::Severity::DEBUG,
    info: Logger::Severity::INFO,
    warn: Logger::Severity::WARN,
    error: Logger::Severity::ERROR,
    fatal: Logger::Severity::FATAL
  }.freeze

  @show_thread_message = false
  attr_accessor :show_thread_message
  attr_reader :site

  def initialize(logfile, env_config, site = nil)
    super()

    @level = env_config['log_level']
    @shift_age = env_config['log_shift_age']

    @logger = Logger.new(logfile, @shift_age, level: @level)
    @show_thread_message = false
    @site = site

    @message_queue = Queue.new
    @thread_group = ThreadGroup.new

    @plotter_thread = Thread.fork do
      loop do
        params = @message_queue.deq
        output(params: params)
      end
    end
  end

  # generate methods named as each levels
  LEVELS.each do |level|
    define_method(level.to_s) do |*args|
      enqueue(level, *args)
    end
  end

  def close(grace: false)
    @logger.close
    if grace
      @thread_group.list.each(&:join)
    else
      @thread_group.list.each(&:kill)
    end
    @plotter_thread.kill
  end

  def readline(prompt, add_history: true, allow_empty: false)
    loop do
      line = Readline.readline(prompt, true)
      info 'readline', prompt + line, to_console: false

      Readline::HISTORY.pop if line.empty? || !add_history

      next if line.empty? && !allow_empty

      begin
        words = line.shellsplit
      rescue StandardError => e
        error 'readline', e.to_s
        next
      end

      return { line: line, words: words }
    end
  rescue Interrupt
    puts ''
    retry
  end

  private

  def enqueue(level, sender, msg, to_console: true, force_to_console: false)
    msg = format(msg)

    colored_msg = to_color(msg, level)

    params = {
      level: SEVERITY[level],
      sender: sender.to_s,
      message: colored_msg,
      to_console: should_to_console?(to_console, force_to_console)
    }

    if Thread.current == Thread.main
      output(params: params)
    else
      t = Thread.fork do
        @message_queue.enq(params)
      end
      @thread_group.add t
    end
  end

  def format(msg)
    if msg.is_a? Exception
      lines = [msg.class.name, msg.to_s]
      lines.concat msg.backtrace if msg.backtrace
      msg = lines.join("\n")
    end
    msg
  end

  def to_color(msg, level)
    if COLOR[level]
      COLOR[level] + msg.to_s + Console::TextAttr::RESET
    else
      msg.to_s
    end
  end

  def should_to_console?(to_console, force_to_console)
    (Thread.current == Thread.main && to_console) || (to_console && @show_thread_message) || force_to_console
  end

  def output(params: nil)
    synchronize do
      $stdout.puts params[:message] if params[:to_console]
      @thread_group.add output_thread(params)
    end
  end

  def output_thread(params)
    Thread.fork params do |p|
      begin
        @logger.add(p[:level], p[:message], p[:sender])
      rescue StandardError => e
        $stdout.puts(COLOR[:fatal] +
                       e.to_s + "\n" +
                       e.backtrace.join("\n") +
                       TextAttr::RESET)
      end
    end
  end
end
