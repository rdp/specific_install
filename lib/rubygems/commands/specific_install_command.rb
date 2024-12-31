require 'rubygems/command_manager'
require 'rubygems/dependency_installer'

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

    add_option('-b', '--branch BRANCH', arguments) do |branch, options|
      options[:branch] = branch
    end

    add_option('-d', '--directory DIRECTORY', arguments) do |directory, options|
      options[:directory] = directory
    end

    add_option('-r', '--ref COMMIT-ISH', arguments) do |ref, options|
      options[:ref] = ref
    end

    add_option('-t', '--tag TAG', arguments) do |tag, options|
      options[:tag] = tag
    end

    add_option('-u', '--user-install', arguments) do |userinstall, options|
      options[:userinstall] = userinstall
    end

    add_option('-i', '--install-dir INSTALL_DIR', arguments) do |installdir, options|
      options[:installdir] = installdir
    end

    add_option('-f', '--force', arguments) do |force, options|
      options[:force] = force
    end

    add_option('--ignore-dependencies', arguments) do |ignore_dependencies, options|
      options[:ignore_dependencies] = ignore_dependencies
    end

    add_option('--minimal-deps', arguments) do |minimal_deps, options|
      options[:minimal_deps] = minimal_deps
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
    @tag ||= set_tag
    @installdir ||= set_installdir
    if @loc.nil?
      raise ArgumentError, "No location received. Use like `gem specific_install -l http://example.com/rdp/specific_install`"
    end
    require 'tempfile' if not defined?(Tempfile)
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

  private

  def git(*commands)
    system "git #{commands.join(' ').chomp(' ')}"
    raise "'$ git #{commands.join(' ').chomp(' ')}' exited with an error" if $?.exitstatus != 0
  end

  def break_unless_git_present
    unless system("git --version") || system("sh -c 'command -V git'")
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
    git "clone", @loc, @top_dir, redirect_for_specs
    install_from_git(@src_dir)
  end

  def gem_name
    @gem_name ||= @loc.split("/").last
  end

  def install_git
    output.puts 'git installing from ' + @loc

    redirect_for_specs = ENV.fetch( "SPECIFIC_INSTALL_SPEC" ) { "" }
    git "clone", @loc, @top_dir, redirect_for_specs
    install_from_git(@src_dir)
  end

  def install_shorthand
    output.puts "Installing from git@github.com:#{@loc}.git"

    redirect_for_specs = ENV.fetch( "SPECIFIC_INSTALL_SPEC" ) { "" }
    git "clone", "git@github.com:#{@loc}.git", @top_dir, redirect_for_specs
    install_from_git(@src_dir)
  end

  def download( full_url, output_name )
    require 'open-uri' if not defined?(OpenURI)
    File.open(output_name, "wb") do |output_file|
      uri = URI.parse(full_url)
      output_file.write(uri.read)
    end
  end

  def install_from_git(dir)
    Dir.chdir @top_dir do
      change_to_branch(@branch) if @branch
      reset_to_commit(@ref) if @ref
      change_to_tag(@tag) if @tag
      git "submodule", "update", "--init", "--recursive" # Issue 25
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

  def set_tag
    options[:tag]
  end

  def set_installdir
    options[:installdir]
  end

  def success_message
    output.puts 'Successfully installed'
  end

  def install_gemspec
    gem = find_or_build_gem
    if gem
      install_options = {}
      install_options[:user_install] = options[:userinstall].nil? ? nil : true
      install_options[:install_dir] = options[:installdir] if options[:installdir]
      install_options[:force] = options[:force].nil? ? nil : true
      install_options[:ignore_dependencies] = options[:ignore_dependencies].nil? ? nil : true
      install_options[:minimal_deps] = options[:minimal_deps].nil? ? nil : true
      inst = Gem::DependencyInstaller.new install_options
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
      File.exist?(gemspec_file(name))
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
    git "checkout", branch
  end

  def reset_to_commit(ref)
    git "reset", "--hard", ref
    git "show", "-q"
  end

  def change_to_tag(tag)
    git "checkout", tag
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
