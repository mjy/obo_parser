
[https://secure.travis-ci.org/mjy/obo_parser.png?branch=master](http://travis-ci.org/mjy/obo_parser?branch=master)

# obo_parser

A simple Ruby gem for parsing OBO 1.2 (?4) formatted ontology files.  Useful for reporting, comparing, and mapping data to other databases.  There is presently no functionality for logical inference across the ontology.

## Installation

    gem install obo_parser

## Use

### General 

    require 'rubygems'
    require 'obo_parser'
    o = parse_obo_file(File.read('my_ontology.obo'))  # => An OboParser instance  
    first_term = o.terms.first                        # => An OboParser#Term instance 
   
    first_term.id.value                                 # => 'HAO:1234'
 
    d = first_term.def                                  # => An OboParser#Tag instance
    d.tag                                               # => 'def'
    d.value                                             # => 'Some defintition'
    d.xrefs                                             # => ['xref:123', 'xref:456'] 
    d.comment                                           # => 'Some comment'
    
    t = first_term.name                                 # => An OboParser#Tag instance    
    t.tag                                               # => 'name'
    t.value                                             # => 'Some Term name' 
    
    o = first_term.other_tags                           # => [OboParser#Tag, ... ] An array of tags that are not specially referenced in an OboParser::Stanza
    o.first                                             # => An OboParser#Tag instance    

    first_typedef = o.typdefs.first                   # => An OboParser#Typdef instance 
    first_typdef.id.value                               # => 'Some typedef id'
    first_typdef.name.value                             # => 'Some typedef name'

    o.terms.first.tags_named('synonym')               # => [OboParser#Tag, ... ]
    o.terms.first.tags_named('synonym').first.tag     # => 'synonym'
    o.terms.first.tags_named('synonym').first.value   # => 'Some label'

    o.terms.first.relationships                       # => [['relationship', 'FOO:123'], ['other_relationship', 'FOO:456'] ...] An array of [relation, related term id], includes 'is_a', 'disjoint_from' and Typedefs

### Convenience methods  
    
    o.term_hash                                       # => { term (String) => id (String), ... for each [Term] in the file. } !! Assumes names terms are unique, they might not be, in which case you get key collisions. 
    o.id_hash                                         # => { id (String) => term (String), ... for each [Term] in the file. } 

See also /test/test_obo_parser.rb

## Utilties

A small set of methods (e.g. comparing OBO ontologies) utilizing the gem are included in /lib/utilities.rb.  For example: 1) shared labels across sets of ontologies can be found and returned, 2) ontologies can be dumped into a simple Cytoscape node/edge format; 3) given a set of correspondances between two ontologies various reports can be made. 

### Viz
   
    OboParser::Utilities::Viz.mock_coordinate_space(o, size: 100) # => STDOUT tab delimited table with x, y, z, identifier, label 

## Documentation

Code documentation is slowly being formalized using Yard.

## Contributing

Fork, test, code, test, pull request.

## Copyright

Copyright (c) 2010-2017 Matt Yoder. See LICENSE for details.

## License

MIT
