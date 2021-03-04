# frozen_string_literal: true

# Copyright (c) 2017-present, BigCommerce Pty. Ltd. All rights reserved
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
# Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
# WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'gruf/version'

Gem::Specification.new do |spec|
  spec.name          = 'gruf'
  spec.version       = Gruf::VERSION
  spec.authors       = ['Shaun McCormick']
  spec.email         = ['splittingred@gmail.com']
  spec.licenses      = ['MIT']

  spec.summary       = 'gRPC Ruby Framework'
  spec.description   = 'gRPC Ruby Framework for building complex gRPC applications at scale'
  spec.homepage      = 'https://github.com/bigcommerce/gruf'

  spec.files         = Dir['README.md', 'CHANGELOG.md', 'CODE_OF_CONDUCT.md', 'lib/**/*', 'gruf.gemspec']
  spec.executables << 'gruf'
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.6', '< 3.1'

  spec.add_development_dependency 'bundler', '~> 1.11'
  spec.add_development_dependency 'bundler-audit', '>= 0.6'
  # rubocop:disable Gemspec/RubyVersionGlobalsUsage
  spec.add_development_dependency(
    'factory_bot',
    (Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.5') ? '>= 6.1' : '~> 5.2')
  )
  # rubocop:enable Gemspec/RubyVersionGlobalsUsage
  spec.add_development_dependency 'ffaker', '>= 2.15'
  spec.add_development_dependency 'pry', '~> 0.12'
  spec.add_development_dependency 'pry-byebug', '>= 3.9'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '>= 3.8'
  spec.add_development_dependency 'rspec_junit_formatter', '>= 0.4'
  spec.add_development_dependency 'rubocop', '>= 1.0'
  spec.add_development_dependency 'rubocop-performance', '>= 0.0.1'
  spec.add_development_dependency 'rubocop-rspec', '>= 2.0'
  spec.add_development_dependency 'rubocop-thread_safety', '>= 0.3'
  spec.add_development_dependency 'simplecov', '>= 0.16'

  spec.add_runtime_dependency 'activesupport', '> 4'
  spec.add_runtime_dependency 'concurrent-ruby', '> 1'
  spec.add_runtime_dependency 'e2mmap', '~> 0.1'
  spec.add_runtime_dependency 'grpc', '~> 1.10'
  spec.add_runtime_dependency 'grpc-tools', '~> 1.10'
  spec.add_runtime_dependency 'json', '>= 2.3'
  spec.add_runtime_dependency 'slop', '~> 4.6'
  spec.add_runtime_dependency 'thwait', '~> 0.1'
end
