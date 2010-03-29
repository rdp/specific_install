require 'rubygems/command_manager'

class Gem::Commands::InstallFromGit < Gem::Command
  def description
    "Allows you to install an \"edge\" gem straight from its github repository"
  end

  def initialize
    super 'install_from_git', description
    add_option('-g', '--git_location', arguments) do |git_location|
      options[:git_location] = git_location
    end
    add_proxy_option
  end

  def execute
    say "This command is deprecated, Gemcutter.org is the primary source for gems."
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

Gem::CommandManager.instance.register_command 'install_from_git'
