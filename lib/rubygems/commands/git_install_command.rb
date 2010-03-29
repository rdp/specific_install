require 'rubygems/command_manager'

class Gem::Commands::GitInstallCommand < Gem::Command

  def description
    "Allows you to install an \"edge\" gem straight from its github repository (like -g  git://github.com/rdp/ruby_tutorials_core.git)"
  end

  def initialize
    super 'git_install', description
    add_option('-g', '--git_location', arguments) do |git_location|
      options[:git_location] = git_location
    end
  end
  
  def arguments
    "GITHUB_LOCATION like http://github.com/rdp/ruby_tutorials_core or git://github.com/rdp/ruby_tutorials_core.git"
  end
  
  def usage
    "#{program_name} [GITHUB_LOCATION]"
  end
  
  def execute
    if loc = options[:git_location]
      say 'getting', loc
    else
      say 'git location is required'
    end
  end
  
end

Gem::CommandManager.instance.register_command :git_install