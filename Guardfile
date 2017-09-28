interactor :simple

guard :rubocop, all_on_start: false do
  watch(/(.+)\.rb$/)
  watch(/(?:.+\/)?\.rubocop\.yml$/) { |m| File.dirname(m[0]) }
end

guard :yard, all_on_start: false do
  watch(/app\/lib\/[^\/]+\.rb/)
  watch(/app\/models\/.+\.rb/)
  watch(/app\/commands\/.+\.rb/)
end

guard :rspec, cmd: 'rspec', all_on_start: false do
  watch(/spec\/.+\/(.+_spec\.rb)/)
  watch(/app\/commands\/(.+)\.rb/) { |m| "spec/commands/#{m[1]}_spec.rb" }
  watch(/app\/models\/(.+)\.rb/) { |m| "spec/models/#{m[1]}_spec.rb" }
  watch(/app\/report_templates\/(.+)\.slim/) { 'spec/commands/report_commands_spec.rb' }
  watch(/app\/lib\/.+\.rb/) { 'spec/commands/' }
end
