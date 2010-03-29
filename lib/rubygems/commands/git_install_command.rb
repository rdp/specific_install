require 'rubygems/command_manager'

class Gem::Commands::GitInstallCommand < Gem::Command

  def description
    "Allows you to install an \"edge\" gem straight from its github repository (like -g  git://github.com/rdp/ruby_tutorials_core.git)"
  end

  def initialize
    super 'git_install', description
    add_option('-g', '--git_location GIT_LOCATION', arguments) do |git_location|
      options[:git_location] = git_location
    end
  end
  
  def arguments
    "GIT_LOCATION like http://github.com/rdp/ruby_tutorials_core or git://github.com/rdp/ruby_tutorials_core.git"
  end
  
  def usage
    "#{program_name} [GIT_LOCATION]"
  end
  
  def execute
    require 'tempfile'
    require 'backports'
    require 'fileutils'
    if loc = options[:git_location]
      # options are
      # http://github.com/githubsvnclone/rdoc.git
      # git://github.com/githubsvnclone/rdoc.git
      # git@github.com:rdp/install_from_git.git
      # http://github.com/rdp/install_from_git [later]
      if !loc.end_with?('.git')
       say 'error: must end with .git to be a git repository'
      else
       say 'git installing from ' + loc
       dir = Dir.mktmpdir
       system("git clone #{loc} #{dir}")
       Dir.chdir dir do
        for command in ['', 'rake gemspec', 'rake gem', 'rake build', 'rake package'] do
          system command
          if install_gemspec
            puts 'gem installed'
            return
          end          
        end
       end
      end
       
    else
      say 'git location is required'
    end
  end
  
  private
  
  def install_gemspec
    if gemspec = Dir['*.gemspec'][0]
      system("gem build #{gemspec}")
      system("gem install *.gem")
      true
    else
      if gem = Dir['pkg/*.gem'][0]
        system("gem install #{gem}")
        true
      else
        false
      end
    end
  end
  
end

Gem::CommandManager.instance.register_command :git_install