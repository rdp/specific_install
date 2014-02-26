require 'rspec'
require 'rspec/mocks'

if RUBY_VERSION > '1.9.0'
  require 'simplecov'
  require 'simplecov-vim/formatter'
  SimpleCov.start do
    formatter SimpleCov::Formatter::VimFormatter
  end

end
require File.dirname(__FILE__) + "/../lib/rubygems_plugin"
