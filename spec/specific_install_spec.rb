require 'rubygems'
require './spec_helper'
require 'stringio'
require 'open3'

describe Gem::Commands::SpecificInstallCommand do
  before do
    module Kernel
      alias_method :real_system, :system

      def system(cmd)
        'system "#{cmd}"'
      end

      def puts(cmd)
        cmd
      end
    end

  end
  after do
    module Kernel
      alias_method :system, :real_system
    end
  end

  subject { Gem::Commands::SpecificInstallCommand.new(StringIO.new) }
  describe "#gem_name" do
    it "sets gem_name from location" do
      subject.instance_variable_set(:@loc, "stuff/foo/bar")
      expect(subject.gem_name).to eq("bar")
    end
  end

  context "disable #install_from_git" do
    before do
      class Gem::Commands::SpecificInstallCommand
        def install_from_git(dir)
          dir
        end
      end
      subject.instance_variable_set(:@top_dir, "foo")
    end
    describe "#install_git" do
      before do
        subject.instance_variable_set(:@loc, "bar")
      end
      it "sends correct command to system" do
        subject.should_receive(:system).with(/git clone bar foo/)
        subject.install_git
      end
    end

    describe "#download" do
      it "downloads a gem" do
        Dir.mktmpdir do |tmpdir|
          url = "https://rubygems.org/downloads/specific_install-0.2.7.gem"
          output_name = "specific_install.gem"
          subject.download(url, output_name)
          expect(File.exists?(output_name)).to be_true
        end
      end
    end

    describe "#install_shorthand" do
      it "formats the shorthand into a git repo" do
        subject.instance_variable_set(:@loc, "bar/zoz")
        subject.should_receive(:system).with(%r{git clone git@github.com:bar/zoz.git foo})
        subject.install_shorthand
      end
    end
  end

  describe "#success_message" do
    it "returns correct message" do
      subject.output.should_receive(:puts).with('Successfully installed')
      subject.success_message
    end
  end

  describe "#install_gemspec" do
    context "when no gemspec or gem" do
      xit "returns false" do
        expect( subject.install_gemspec ).to eq(false)
      end
    end
  end

  describe "#gemspec_exists?" do
    it "response true to when exists" do
      expect( subject.gemspec_exists? ).to be_true
    end

    it "responds false when not present" do
      expect( subject.gemspec_exists?("*.gemNOTPRESENT") ).to be_false
    end
  end

  describe "#gemfile" do
    it "response false when not existing" do
      expect( subject.gemfile("*.gemNOTPRESENT") ).to be_false
    end
    it "response true to when exists" do
      expect( subject.gemfile("**/*.gem") ).to be_true
    end
  end

  describe "#determine_source_and_install" do
    it "executes http gem requests" do
        subject.instance_variable_set(:@loc, "http://example.com/rad.gem")
        subject.should_receive(:install_gem)
        subject.determine_source_and_install
    end
    it "executes https gem requests" do
        subject.instance_variable_set(:@loc, "https://example.com/rad.gem")
        subject.should_receive(:install_gem)
        subject.determine_source_and_install
    end
    it "executes https git install requests" do
        subject.instance_variable_set(:@loc, "https://example.com/rad.git")
        subject.should_receive(:install_git)
        subject.determine_source_and_install
    end
    it "executes git url git install requests" do
        subject.instance_variable_set(:@loc, "git@github.com:example/rad.git")
        subject.should_receive(:install_git)
        subject.determine_source_and_install
    end
    it "executes shorthand github install requests" do
        subject.instance_variable_set(:@loc, "example/rad")
        subject.should_receive(:install_shorthand)
        subject.determine_source_and_install
    end
    it "executes shorthand github install requests" do
        subject.instance_variable_set(:@loc, "example")
        subject.should_receive(:warn)
        subject.determine_source_and_install
    end
  end

  describe "#set_location" do
    it "sets from options[location]" do
      subject.options[:location] = "example"
      expect( subject.set_location ).to eq("example")
    end
    it "sets from options[args]" do
      subject.options[:location] = nil
      subject.options[:args] = ["args"]
      expect( subject.set_location ).to eq("args")
    end
    it "sets neither and results in nil" do
      subject.options[:location] = nil
      subject.options[:args] = []
      expect( subject.set_location ).to be_nil
    end
  end

  describe "#execute" do
    it "raises error when no location received" do
      subject.options[:location] = nil
      subject.options[:args] = []
      expect{ subject.execute }.to raise_error(ArgumentError)
    end
  end

end


describe "Integration Tests" do

  $STDOUT = StringIO.new
  let(:output) { StringIO.new }
  subject { Gem::Commands::SpecificInstallCommand.new(output) }
  before(:all) do
    # ENV.store( "SPECIFIC_INSTALL_SPEC", '2&> /dev/null' )
  end
  before(:each) do
    `gem uninstall specific_install --executables 2&> /dev/null`
    `rake install 2&> /dev/null`
  end

  after(:all) do
    `gem uninstall specific_install --executables 2&> /dev/null`
    `gem install specific_install`
    ENV.delete( "SPECIFIC_INSTALL_SPEC" )
  end

  context "working URIs" do
    it "installs from https" do
      url = "https://github.com/rdp/specific_install.git"
      subject.instance_variable_set(:@loc, url)
      subject.options[:args] = []
      stdout, status = Open3.capture2 "gem specific_install #{url}"
      expect(stdout).to match(/Successfully installed/)
    end
    it "installs from http" do
      url = "http://github.com/rdp/specific_install.git"
      subject.instance_variable_set(:@loc, url)
      subject.options[:args] = []
      stdout, status = Open3.capture2 "gem specific_install #{url}"
      expect(stdout).to match(/Successfully installed/)
    end
    it "installs from shorthand" do
      url = "rdp/specific_install"
      subject.instance_variable_set(:@loc, url)
      subject.options[:args] = []
      stdout, status = Open3.capture2 "gem specific_install #{url}"
      expect(stdout).to match(/Successfully installed/)
    end
    it "installs from git" do
      url = "git@github.com:zph/buff.git"
      stdout, status = Open3.capture2 "gem specific_install #{url}"
      expect(stdout).to match(/Successfully installed/)
    end
    it "installs from packaged gem" do
      url = "https://rubygems.org/downloads/specific_install-0.2.7.gem"
      stdout, status = Open3.capture2 "gem specific_install #{url}"
      expect(stdout).to match(/Successfully installed/)
    end
  end
end if ENV['SPECIFIC_INSTALL_INTEGRATION_SPECS']
