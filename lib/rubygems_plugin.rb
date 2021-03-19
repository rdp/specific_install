begin
  require "specific_install/version"
  require "rubygems/commands/specific_install_command"
rescue LoadError
  # This happens with `bundle exec gem build <gemspec>` commands.
  # But in that context we don't care.
end
