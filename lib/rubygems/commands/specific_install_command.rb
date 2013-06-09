require 'rubygems/command_manager'

class Gem::Commands::SpecificInstallCommand < Gem::Command

  def description
    "Allows you to install an \"edge\" gem straight from its github repository or from a web site"
  end

  def initialize
    super 'specific_install', description
    add_option('-l', '--location LOCATION', arguments) do |location, something|
      options[:location] = location
    end
  end

  def arguments
    "LOCATION like http://github.com/rdp/ruby_tutorials_core or git://github.com/rdp/ruby_tutorials_core.git or http://host/gem_name.gem"
  end

  def usage
    "#{program_name} [LOCATION]"
  end

  def execute
    require 'tempfile'
    require 'backports'
    require 'fileutils'
    if loc = options[:location]
      # options are
      # http://github.com/githubsvnclone/rdoc.git
      # git://github.com/githubsvnclone/rdoc.git
      # git@github.com:rdp/install_from_git.git
      # http://github.com/rdp/install_from_git [later]
      # http://host/gem_name.gem
      dir = Dir.mktmpdir
    begin
      if loc.start_with?('http://') && loc.end_with?('.gem')
        Dir.chdir dir do
          say "downloading #{loc}"
          system("wget #{loc}")
          if install_gemspec
            puts "successfully installed"
            return
          else
            puts "failed"
          end
        end
      elsif !loc.end_with?('.git')
       say 'error: must end with .git to be a git repository'
      else
       say 'git installing from ' + loc
       system("git clone #{loc} #{dir}")
       Dir.chdir dir do
        for command in ['', 'rake gemspec', 'rake gem', 'rake build', 'rake package'] do
          system command
          if install_gemspec
            puts 'successfully installed'
            return
          end
        end
       end
      end
      puts 'failed'
    ensure
      FileUtils.rm_rf dir # just in case [?]
    end
    else
      say 'location is required'
    end
  end

  private

  def install_gemspec
    if gemspec = Dir['*.gemspec'][0]
      system("gem build #{gemspec}")
      system("gem install *.gem")
      true
    else
      if gem = Dir['**/*.gem'][0]
        system("gem install #{gem}")
        true
      else
        false
      end
    end
  end

end

Gem::CommandManager.instance.register_command :specific_install
