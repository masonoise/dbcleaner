notification :tmux,
  display_message: true,
  timeout: 5,
  default_message_format: '%s >> %s',
  line_separator: ' > ',
  color_location: 'status-left-bg'

guard 'rspec', :failed_mode => :focus, :all_on_start => false, :all_after_pass => false do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
  watch(%r{^spec/support/(.+)\.rb$})                  { "spec" }
end


guard :rubocop do
  watch(%r{.+\.rb$})
  watch(%r{(?:.+/)?\.rubocop\.yml$}) { |m| File.dirname(m[0]) }
end
