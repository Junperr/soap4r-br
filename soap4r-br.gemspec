$:.unshift File.expand_path("../lib", __FILE__)
require 'soap/version'

Gem::Specification.new do |s|
  s.name = 'soap4r-br'
  s.version = SOAP::VERSION::STRING

  s.authors = "Aristide D, Laurence A. Lee, Hiroshi NAKAMURA"
  s.email = "aristideduhem@gmail.com, rubyjedi@gmail.com, nahi@ruby-lang.org"
  s.homepage = "https://github.com/Junperr/soap4r-br"
  s.license = "Ruby"

  s.summary     = "Soap4R-ng with more restriction handling "
  s.description = "Soap4R BetterRestriction (from version maintained by RubyJedi) for Ruby 1.8 thru 2.1 and beyond"

  s.requirements << 'none'
  s.require_path = 'lib'

  s.files = `git ls-files lib bin`.split("\n")
  s.executables = [ "wsdl2ruby.rb", "xsd2ruby.rb" ]
end