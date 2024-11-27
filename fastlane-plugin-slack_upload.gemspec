lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/slack_upload/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-slack_upload'
  spec.version       = Fastlane::SlackUpload::VERSION
  spec.authors       = ['Dawid Cieslak', 'Zvonimir Rudinski']
  spec.email         = ['cieslakdawid@gmail.com', 'zvonimir.rudinski@noubis.com']

  spec.summary       = 'Uploads specified file to Slack'
  spec.homepage      = "https://github.com/NoubisServices/fastlane-plugin-slack_upload"
  spec.license       = "MIT"

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  # Don't add a dependency to fastlane or fastlane_re
  # since this would cause a circular dependency

  spec.add_development_dependency('bundler')
  spec.add_development_dependency('fastlane', '>= 2.97.0')
  spec.add_development_dependency('pry')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('rspec')
  spec.add_development_dependency('rspec_junit_formatter')
  spec.add_development_dependency('rubocop', '0.55')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
end
