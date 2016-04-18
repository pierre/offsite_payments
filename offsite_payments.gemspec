$:.push File.expand_path("../lib", __FILE__)
require 'offsite_payments/version'

Gem::Specification.new do |s|
  s.platform     = Gem::Platform::RUBY
  s.name         = 'koffsite_payments'
  s.version      = OffsitePayments::VERSION
  s.summary      = 'Fork of the Shopify Offsite Payments gem for Kill Bill.'
  s.description  = 'This fork contains unmerged pull requests for additional gateways.'
  s.license      = "MIT"

  s.author = 'Kill Bill core team'
  s.email = 'killbilling-users@googlegroups.com'
  s.homepage = 'http://killbill.io/'

  s.files = Dir['CHANGELOG', 'README.md', 'MIT-LICENSE', 'lib/**/*']
  s.require_path = 'lib'

  s.add_dependency('activesupport', '>= 3.2.14', '< 5.1')
  s.add_dependency('i18n', '~> 0.5')
  s.add_dependency('money', '< 7.0.0')
  s.add_dependency('builder', '>= 2.1.2', '< 4.0.0')
  s.add_dependency('active_utils', '~> 3.2.0')
  s.add_dependency('nokogiri', "~> 1.4")
  s.add_dependency('actionpack', ">= 3.2.20", "< 5.1")

  s.add_development_dependency('rake')
  s.add_development_dependency('test-unit', '~> 3.0')
  s.add_development_dependency('mocha', '~> 1.0')
  s.add_development_dependency('rails', '>= 3.2.14')
  s.add_development_dependency('thor')
end
