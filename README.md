# Gem::SpecificInstall

## Installation

Add this line to your application's Gemfile:

    gem 'specific_install'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install specific_install

## Usage

A Rubygem plugin that allows you to install an "edge" gem straight from its github repository,
  or install one from an arbitrary web url:

examples:

`
  $ gem specific_install https://github.com/githubsvnclone/rdoc.git
`

Or more explicitly:

`
  $ gem specific_install -l http://github.com/githubsvnclone/rdoc.git
`

Or very tersely:

`
  $ gem specific_install githubsvnclone/rdoc
`

Or a specific branch

`
  $ gem specific_install http://github.com/githubsvnclone/rdoc.git edge
`

Or a specific branch in an explicit way

`
  $ gem specific_install -l http://github.com/githubsvnclone/rdoc.git -b edge
`

Or a specific subdirectory in a repo

`
  $ gem specific_install https://github.com/orlandohill/waxeye -d src/ruby
`

Or install in the users personal gem directory

`
  $ gem specific_install https://github.com/orlandohill/waxeye -u
`

The following URI types are accepted:

- http(s)://github.com/rdp/specific_install.git
- http(s)://github.com/rdp/specific_install-current.gem
- http://github.com/rdp/specific_install.git
- http://somewhere_else.com/rdp/specific_install.git
- git@github.com:rdp/specific_install.git
- rdp/specific_install # implies github

### Additional Options

    -l --location URL of resource
      Formats of URL/Resource
        * Full URL to HTTP Repo `https://github.com/rdp/specific_install.git`
        * Full URL to Git Repo  `git@github.com:rdp/specific_install.git`
        * URL of Pre-Built Gem  `http://example.com/specific_install.gem`
        * Github Repo shortcode `rdp/specific_install`

    -b --branch BRANCH to use for Gem creation
      Branch option does a `git checkout BRANCH` before `gem build GEM`
      Example:
          `git specific_install -l rdp/specific_install -b pre-release`
      Note: This feature is new and may not fail gracefully.

    -d --directory DIRECTORY in source
      This will change the directory in the downloaded source directory
      before building the gem.

    -r, --ref COMMIT-ISH to use for Gem creation
      Ref option does a `git reset --hard COMMIT-ISH` before `gem build GEM`

    -u, --user-install to indicate that the gem should be unpacked into the users personal gem directory.
      This will install the gem in the user folder making it possible to use specific_install without root access.

    `git_install` is aliased to the behavior of `specific_install`
      This alias is shorter and is more intention revealing of the gem's behavior.
      
    -t, --tag to indicate git tag to be checked out.
      This will use/install a specific git tag.
      
## Internal Behavior

It runs `git clone`, and `rake install,` install the gem, then deletes the temp directory.

## Compatibility

v0.2.10 is known to work against Rubygems v2.2.2 and has a compatibility issue with Rubygems v1.8.25 (possible other older Rubygems).
Work-arounds: Upgrade Rubygems via `rvm rubygems current` or install older version of `specific_install`.
## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

Enjoy!

Copyright 2010-2014 Roger Pack - `http://github.com/rdp/specific_install`
