require 'rubygems/command_manager'
require 'rubygems/dependency_installer'
require 'tempfile'
require 'backports'
require 'fileutils'
require 'open-uri'

class Gem::Commands::SpecificInstallCommand < Gem::Command
  attr_accessor :output

  def description
    "Allows you to install an 'edge' gem straight from its github repository or from a web site"
  end

  def initialize(output=STDOUT)
    super 'specific_install', description
    @output = output

    add_option('-l', '--location LOCATION', arguments) do |location|
      options[:location] = location
    end

    add_option('-b', '--branch LOCATION', arguments) do |branch|
      options[:branch] = branch
    end

  end

  def arguments
    "LOCATION like http://github.com/rdp/ruby_tutorials_core or git://github.com/rdp/ruby_tutorials_core.git or http://host/gem_name.gem\n" +
    "BRANCH (optional) like beta, or new-feature"
  end

  def usage
    "#{program_name} [LOCATION] [BRANCH]"
  end

  def execute
    @loc ||= set_location
    @branch ||= set_branch if set_branch
    if @loc.nil?
      raise ArgumentError, "No location received. Use `gem specific_install -l http://example.com/rdp/specific_install`"
    end
    Dir.mktmpdir do |dir|
      @dir = dir
      determine_source_and_install
    end
  end

  def determine_source_and_install
    case @loc
    when /^https?(.*)\.gem$/
      install_gem
    when /\.git$/
      install_git
    when %r(.*/.*)
      install_shorthand
    else
      warn 'Error: must end with .git to be a git repository' +
        'or be in shorthand form: rdp/specific_install'
    end
  end

  def install_gem
    Dir.chdir @dir do
      output.puts "downloading #{@loc}"
      download(@loc, gem_name)

      if install_gemspec
        success_message
      else
        output.puts "Failed"
      end
    end
  end

  def gem_name
    @gem_name ||= @loc.split("/").last
  end

  def install_git
    output.puts 'git installing from ' + @loc

    redirect_for_specs = ENV.fetch( "SPECIFIC_INSTALL_SPEC" ) { "" }
    system("git clone #{@loc} #{@dir} #{redirect_for_specs}")
    install_from_git(@dir)
  end

  def install_shorthand
    output.puts "Installing from git@github.com:#{@loc}.git"

    redirect_for_specs = ENV.fetch( "SPECIFIC_INSTALL_SPEC" ) { "" }
    system("git clone git@github.com:#{@loc}.git #{@dir} #{redirect_for_specs}")
    install_from_git(@dir)
  end

  def download( full_url, output_name )
    File.open(output_name, "wb") do |output_file|
      uri = URI.parse(full_url)
      output_file.write(uri.read)
    end
  end

  def install_from_git(dir)
    Dir.chdir dir do
      change_to_branch(@branch) if @branch
      # reliable method
      if install_gemspec
        success_message
        exit 0
      end

      # legacy method
      ['', 'rake gemspec', 'rake gem', 'rake build', 'rake package'].each do |command|
        system command
        if install_gemspec
          success_message
          exit 0
        end
      end
    end
  end

  def set_location
    options[:location] || options[:args][0]
  end

  def set_branch
    options[:branch] || options[:args][1]
  end

  def success_message
    output.puts 'Successfully installed'
  end

  def install_gemspec
    gem = find_or_build_gem

    inst = Gem::DependencyInstaller.new
    inst.install gem
  end

  def find_or_build_gem
    if gemspec_exists?
      gemspec = Gem::Specification.load(gemspec_file)
      Gem::Package.build gemspec
    elsif gemfile
      gemfile
    else
      raise ArgumentError, "Can't find gemspec or gem"
    end
  end

  def gemspec_file(name = "*.gemspec")
    Dir[name][0]
  end

  def gemspec_exists?(name = "*.gemspec")
    if gemspec_file(name)
      File.exists?(gemspec_file(name))
    else
      false
    end
  end

  def gemfile(name = '**/*.gem')
    if Dir[name].empty?
      false
    else
      Dir[name][0]
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
