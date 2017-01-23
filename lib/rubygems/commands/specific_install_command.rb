require 'rubygems/command_manager'
require 'rubygems/dependency_installer'
require 'tempfile'
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

    add_option('-l', '--location LOCATION', arguments) do |location, options|
      options[:location] = location
    end

    add_option('-b', '--branch LOCATION', arguments) do |branch, options|
      options[:branch] = branch
    end

    add_option('-d', '--directory DIRECTORY', arguments) do |directory, options|
      options[:directory] = directory
    end

    add_option('-r', '--ref COMMIT-ISH', arguments) do |ref, options|
      options[:ref] = ref
    end
  end

  def arguments
    "LOCATION like http://github.com/rdp/ruby_tutorials_core or git://github.com/rdp/ruby_tutorials_core.git or http://host/gem_name.gem\n" +
    "BRANCH (optional) like beta, or new-feature\n" +
    "DIRECTORY (optional) This will change the directory in the downloaded source directory before building the gem."
  end

  def usage
    "#{program_name} [LOCATION] [BRANCH] (or command line options for the same)"
  end

  def execute
    @loc ||= set_location
    @branch ||= set_branch if set_branch
    @ref ||= set_ref
    if @loc.nil?
      raise ArgumentError, "No location received. Use like `gem specific_install -l http://example.com/rdp/specific_install`"
    end
    Dir.mktmpdir do |dir|
      if subdir = options[:directory]
        abort("Subdir '#{subdir}' is not a valid directory") unless valid_subdir?(subdir)
        @top_dir = dir
        @src_dir = File.join(dir, subdir)
      else
        @top_dir = @src_dir = dir
      end
      determine_source_and_install
    end
  end

  def break_unless_git_present
    unless system("which git") || system("where git")
      abort("Please install git before using a git based link for specific_install")
    end
  end

  def determine_source_and_install
    case @loc
    when /^https?(.*)\.gem$/
      install_gem
    when /\.git$/
      break_unless_git_present
      install_git
    when /^https?(.*)$/
      break_unless_git_present
      install_http_repo
    when %r(.*/.*)
      break_unless_git_present
      install_shorthand
    else
      warn 'Error: must end with .git to be a git repository' +
        'or be in shorthand form: rdp/specific_install'
    end
  end

  def install_gem
    Dir.chdir @top_dir do
      output.puts "downloading #{@loc}"
      download(@loc, gem_name)

      if install_gemspec
        success_message
      else
        output.puts "Failed"
      end
    end
  end

  def install_http_repo
    output.puts 'http installing from ' + @loc

    @loc = [@loc, '.git'].join unless @loc[/\.git$/]

    redirect_for_specs = ENV.fetch( "SPECIFIC_INSTALL_SPEC" ) { "" }
    system("git clone #{@loc} #{@top_dir} #{redirect_for_specs}")
    install_from_git(@src_dir)
  end

  def gem_name
    @gem_name ||= @loc.split("/").last
  end

  def install_git
    output.puts 'git installing from ' + @loc

    redirect_for_specs = ENV.fetch( "SPECIFIC_INSTALL_SPEC" ) { "" }
    system("git clone #{@loc} #{@top_dir} #{redirect_for_specs}")
    install_from_git(@src_dir)
  end

  def install_shorthand
    output.puts "Installing from git@github.com:#{@loc}.git"

    redirect_for_specs = ENV.fetch( "SPECIFIC_INSTALL_SPEC" ) { "" }
    system("git clone git@github.com:#{@loc}.git #{@top_dir} #{redirect_for_specs}")
    install_from_git(@src_dir)
  end

  def download( full_url, output_name )
    File.open(output_name, "wb") do |output_file|
      uri = URI.parse(full_url)
      output_file.write(uri.read)
    end
  end

  def install_from_git(dir)
    Dir.chdir @top_dir do
      change_to_branch(@branch) if @branch
      reset_to_commit(@ref) if @ref
      system("git submodule update --init --recursive") # issue 25
    end

    Dir.chdir dir do
      # reliable method
      if install_gemspec
        success_message
        exit 0
      end

      # legacy methods
      ['', 'rake gemspec', 'rake gem', 'rake build', 'rake package'].each do |command|
        puts "attempting #{command}..."
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

  def set_ref
    options[:ref] || options[:args][2]
  end

  def success_message
    output.puts 'Successfully installed'
  end

  def install_gemspec
    gem = find_or_build_gem
    if gem
      inst = Gem::DependencyInstaller.new
      inst.install gem
    else
      nil
    end
  end

  def find_or_build_gem
    if gemspec_exists?
      gemspec = Gem::Specification.load(gemspec_file)
      Gem::Package.build gemspec
    elsif gemfile
      gemfile
    else
      nil
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

  def reset_to_commit(ref)
    system("git reset --hard #{ref}")
    system("git show -q")
  end

  DOTDOT_REGEX = /(?:#{File::PATH_SEPARATOR}|\A)\.\.(?:#{File::PATH_SEPARATOR}|\z)/.freeze
  ABS_REGEX = /\A#{File::PATH_SEPARATOR}/.freeze

  def valid_subdir?(subdir)
    !subdir.empty? &&
      subdir !~ DOTDOT_REGEX &&
      subdir !~ ABS_REGEX
  end
end

class Gem::Commands::GitInstallCommand < Gem::Commands::SpecificInstallCommand
end

Gem::CommandManager.instance.register_command :specific_install
Gem::CommandManager.instance.register_command :git_install
