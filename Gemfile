source 'https://rubygems.org'

gem 'activerecord', '5.1.4'
gem 'activesupport', '5.1.4'
gem 'git', '~>1.3.0'
gem 'ipaddress', '~>0.8.3'
gem 'pg', '~>0.20.0'
gem 'rake', '~>12.0.0'
gem 'rb-readline', '0.5.5'
gem 'ruby-filemagic', '~>0.7.0'
gem 'slim', '~>3.0.8'
gem 'sys-proctree', '~>0.0.10', require: %w[sys/proctree sys/proctable]
gem 'terminal-table'

group :development, :test do
  gem 'parser', '~>2.4.0'
  gem 'pry'
  gem 'pry-byebug'
end

group :development do
  gem 'guard', require: false
  gem 'guard-rspec', require: false
  gem 'guard-rubocop', require: false
  gem 'guard-yard', require: false
  gem 'rubocop', '0.49.1', require: false
  gem 'yard', require: false
end

group :test do
  gem 'database_cleaner', '1.6.1'
  gem 'factory_girl', '4.8.0'
  gem 'rspec', '3.6.0'
  gem 'rsync', '1.0.9'
end

# Install gems from test suites and commands
gem_files = %w[test_suites/*/Gemfile ext/commands/*/Gemfile ext/report_templates/*/Gemfile]
basedir = File.expand_path(File.dirname(__FILE__))
gem_files.map { |path| File.join(basedir, path) }.each do |gemfile|
  Dir[gemfile].each do |path|
    eval_gemfile(path) if File.exist?(path)
  end
end
