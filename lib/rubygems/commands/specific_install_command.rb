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
    "BRANCH (optional) like beta, or new-feature"
  end

  def usage
    "#{program_name} [LOCATION] [BRANCH]"
  end

  def execute
    require 'tempfile'
    require 'backports'
    require 'fileutils'
    require 'open-uri'
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
      # rdp/specific_install
    dir = Dir.mktmpdir
    begin
      loc = options[:location]
      case loc
      when /^http(.*)\.gem$/
        Dir.chdir dir do
          say "downloading #{loc}"
          gem_name = loc.split("/").last
          download(loc, gem_name)

          if install_gemspec
            success_message
          else
            puts "failed"
          end
        end
      when /\.git$/
       say 'git installing from ' + loc

       system("git clone #{loc} #{dir}")
       install_from_git(dir)
      when %r(.*/.*)
        puts "Installing from git@github.com:#{loc}.git"

        system("git clone git@github.com:#{loc}.git #{dir}")
        install_from_git(dir)
      else
        puts 'Error: must end with .git to be a git repository' +
        'or be in shorthand form: rdp/specific_install'
      end
    ensure
      FileUtils.rm_rf dir
    end

  end

  private

  def download( full_url, output_name )
    File.open(output_name, "wb") do |output_file|
      output_file.write(open(full_url).read)
    end
  end

  def install_from_git(dir)
    Dir.chdir dir do
      ['', 'rake gemspec', 'rake gem', 'rake build', 'rake package'].each do |command|
        system command
        if install_gemspec
          success_message
          exit 0
        end
      end
    end
  end

  def success_message
    puts 'Successfully installed'
  end

  def install_gemspec
    if gemspec = Dir['*.gemspec'][0]
      change_to_branch(options[:branch]) if options[:branch]
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

  def change_to_branch(branch)
    system("git checkout #{branch}")
    system("git branch")
  end
end

class Gem::Commands::GitInstallCommand < Gem::Commands::SpecificInstallCommand
end

Gem::CommandManager.instance.register_command :specific_install
Gem::CommandManager.instance.register_command :git_install
