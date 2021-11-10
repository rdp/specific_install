require 'rubygems'
require "bundler/gem_tasks"

# how to:
# edit lib/specific_install/version.rb
# rake release, seems to work!

desc "Uninstall specific_install and release, then reinstall"
task :rubygems do
  sh "gem uninstall specific_install --executables"
  Rake::Task["release"].invoke
  sh "gem install specific_install"
end
