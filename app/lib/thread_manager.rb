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
class ThreadManager
  attr_reader :running, :queued, :max, :available
  MAX_THREAD = 30
  def initialize(max_thread = nil)
    @running = 0
    @queued = 0
    @mutex = Mutex.new
    @available = ConditionVariable.new
    @max = max_thread || MAX_THREAD
    @max.freeze
  end

  def waiting
    @queued - @running
  end

  # running thread limiter
  def run_limit(on_wait: nil, after_end: nil)
    started = false
    @mutex.synchronize do
      @queued += 1
      while @running >= @max
        on_wait.call(self) if on_wait.is_a? Proc
        @available.wait(@mutex)
      end
      started = true
      @running += 1
    end

    yield self
  ensure
    @mutex.synchronize do
      @running -= 1 if started
      @queued -= 1
      @available.signal
      after_end.call(self) if after_end.is_a? Proc
    end
  end
end
