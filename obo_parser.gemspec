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

  spec.add_dependency 'rake', '~> 11.1.2'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'awesome_print', '~> 1.8'

end

