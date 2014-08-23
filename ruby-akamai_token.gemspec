require File.expand_path('lib') << '/akamai_token'
require 'date'

Gem::Specification.new do |s|
  s.name        = 'ruby-akamai_token'
  s.version     = AkamaiToken::VERSION
  s.date        = Date.today
  s.summary     = "Akamai Token v2 command line program, extracted into a Ruby module -no CLI!"
  #s.description =<<-DESC
  #DESC
  s.authors     = ['Akamai Technologies, Inc.', 'rentlessGENERATOR']
  s.email       = 'dev@rgenerator.com'
  s.files       = Dir['lib/**/*.rb']
  s.homepage    = 'https://github.com/rgenerator/ruby-akamai_token'
  #s.license     = ''
end
