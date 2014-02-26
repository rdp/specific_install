require 'rubygems'
require "bundler/gem_tasks"

desc "Uninstall specific_install and release, then reinstall"
task :rubygems do
  sh "gem uninstall specific_install --executables"
  Rake::Task["release"].invoke
  sh "gem install specific_install"
end
