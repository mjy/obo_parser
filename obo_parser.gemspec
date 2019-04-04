# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'obo_parser/version'

Gem::Specification.new do |spec|
  spec.name = 'obo_parser'
  spec.version = OboParser::VERSION 

  spec.authors = ["Matt Yoder"]
  spec.email = ["diapriid@gmail.com"]
  spec.date = %q{2011-08-25}
  spec.description = %q{Provides all-in-one object containing the contents of an OBO formatted file.  OBO version 1.2 is targeted, though this should work for 1.0. }
  spec.summary = 'Ruby parsering for OBO files.'
  spec.license = 'MIT'
  spec.homepage = 'http://github.com/mjy/obo_parser'
  spec.files = `git ls-files -z`.split("\x0")
  spec.require_paths = ["lib"]

  spec.add_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.8'
  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'guard-rspec', '~> 4.7.3'
  spec.add_development_dependency 'pry', '~> 0.12'
  spec.add_development_dependency 'awesome_print', '~> 1.8'
  spec.add_development_dependency 'logger', '~> 1.3'

end

