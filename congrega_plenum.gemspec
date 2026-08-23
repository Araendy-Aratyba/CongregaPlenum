# frozen_string_literal: true

require_relative 'lib/version'

Gem::Specification.new do |spec|
  spec.name = 'congrega_plenum'
  spec.version = CongregaPlenum::VERSION
  spec.authors = ['zarbielli']
  spec.email = ['joao.zarbielli@gmail.com']

  spec.summary = 'Ruby client for Câmara dos Deputados open data API'
  spec.description = 'HTTP client with pagination, retries and logging for Câmara dos Deputados open data endpoints.'
  spec.homepage = 'https://github.com/zarbielli/CongregaPlenum'
  spec.required_ruby_version = '>= 3.4.0'
  spec.license = 'GPL-2.0-only'

  spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Package only runtime, type signature and legal/documentation source files.
  # Generated documentation and coverage reports must never ship in the gem.
  spec.files = Dir.chdir(__dir__) do
    Dir.glob(%w[CHANGELOG.md LICENSE README.md lib/**/*.rb sig/**/*.rbs])
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
