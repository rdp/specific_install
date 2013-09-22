require 'simplecov'
require 'simplecov-vim/formatter'
require 'rspec'
require 'rspec/mocks'

SimpleCov.start do
  formatter SimpleCov::Formatter::VimFormatter
end

require 'rubygems_plugin'
