module SpecificInstall
  def self.require_relative(path)
    if Kernel.respond_to?(:require_relative)
      Kernel.require_relative path
    else
      # 1.8, adapted from:
      # https://github.com/marcandre/backports/blob/master/lib/backports/1.9.1/kernel/require_relative.rb
      file = caller[0].split(/:\d/, 2).first
      Kernel.require File.expand_path(path, File.dirname(file))
    end
  end
  require_relative 'rubygems/commands/specific_install_command'
  require_relative 'specific_install/version'
end
