lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "emu/version"

Gem::Specification.new do |spec|
  spec.name          = "emu"
  spec.version       = Emu::VERSION
  spec.authors       = ["Tim Habermaas"]
  spec.email         = ["emu@timhabermaas.com"]

  spec.summary       = %q{Composable decoding library in the spirit of Json.Decode from Elm}
  spec.description   = %q{Emu acts as a replacement for ad-hoc type coercions and strong_parameters.}
  spec.homepage      = "https://github.com/timhabermaas/emu.git"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    #spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    #spec.metadata["homepage_uri"] = spec.homepage
    #spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
    #spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."
  else
    #raise "RubyGems 2.0 or newer is required to protect against " \
    #  "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  spec.files         = ["Gemfile", "LICENSE.txt", "README.md", "Rakefile", "bin/console", "bin/setup", "emu.gemspec",
                        "lib/emu.rb", "lib/emu/version.rb", "lib/emu/decoder.rb", "lib/emu/result.rb"]
  spec.bindir        = "exe"
  spec.executables   = []
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  #spec.add_development_dependency "rake", "~> 10.0"
  #spec.add_development_dependency "minitest", "~> 5.0"
end
