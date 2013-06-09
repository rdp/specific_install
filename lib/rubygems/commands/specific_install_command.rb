require 'rubygems/command_manager'

class Gem::Commands::SpecificInstallCommand < Gem::Command

  def description
    "Allows you to install an \"edge\" gem straight from its github repository or from a web site"
  end

  def initialize
    super 'specific_install', description

    add_option('-l', '--location LOCATION', arguments) do |location|
      options[:location] = location
    end

    add_option('-b', '--branch LOCATION', arguments) do |branch|
      options[:branch] = branch
    end

  end

  def arguments
    "LOCATION like http://github.com/rdp/ruby_tutorials_core or git://github.com/rdp/ruby_tutorials_core.git or http://host/gem_name.gem"
    "BRANCH (optional) like beta"
  end

  def usage
    "#{program_name} [LOCATION] [BRANCH]"
  end

  def execute
    require 'tempfile'
    require 'backports'
    require 'fileutils'
    unless options[:location]
      puts "No location received. Use `gem specific_install -l http://example.com/rdp/specific_install`"
      exit 1
    end
      # options are
      # http://github.com/githubsvnclone/rdoc.git
      # git://github.com/githubsvnclone/rdoc.git
      # git@github.com:rdp/install_from_git.git
      # http://github.com/rdp/install_from_git [later]
      # http://host/gem_name.gem
    dir = Dir.mktmpdir
    begin
      case loc
      when /^http(.*)\.gem$/
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
      when /\.git$/
       say 'git installing from ' + loc
       system("git clone #{loc} #{dir}")
       Dir.chdir dir do
        ['', 'rake gemspec', 'rake gem', 'rake build', 'rake package'].each do |command|
          system command
          if install_gemspec
            puts 'Successfully installed'
            return
          end
        end
       end
      else
        say 'Error: must end with .git to be a git repository'
      end
    ensure
      FileUtils.rm_rf dir
    end

  end

  private

  def install_gemspec
    if gemspec = Dir['*.gemspec'][0]
      change_to_branch(options[:branch]) if options[:branch]
      system("gem build #{gemspec}")
      system("gem install *.gem")
      true
    else
      false
    end

    # if gem = Dir['**/*.gem'][0]
    #   system("gem install #{gem}")
    #   true
    # else
    #   false
    # end
  end

  def change_to_branch(branch)
    system("git checkout #{branch}")
  end
end


Gem::CommandManager.instance.register_command :specific_install
