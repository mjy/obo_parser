require 'test/unit'
require 'rubygems'
require 'ruby-debug'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/obo_parser')) 

class OboParserTest < Test::Unit::TestCase
  def test_truth
    assert true
  end
end

class Test_OboParserBuilder < Test::Unit::TestCase
  def test_builder
    b = OboParser::OboParserBuilder.new
  end
end

class Test_Regex < Test::Unit::TestCase

  def test_some_regex
    assert true 
  end

end

class Test_Lexer < Test::Unit::TestCase

  def test_term
    lexer = OboParser::Lexer.new("[Term]")
    assert lexer.pop(OboParser::Tokens::Term)
  end

  def test_end_of_file
    lexer = OboParser::Lexer.new("    \n\n")
    assert lexer.pop(OboParser::Tokens::EndOfFile)

    lexer = OboParser::Lexer.new("\n")
    assert lexer.pop(OboParser::Tokens::EndOfFile)
  end

  def test_parse_term_stanza
    input = '
      id: PATO:0000015
      name: color hue
      def: "A chromatic scalar-circular quality inhering in an object that manifests in an observer by virtue of the dominant wavelength of the visible light; may be subject to fiat divisions, typically into 7 or 8 spectra." [PATOC:cjm]
      subset: attribute_slim
      is_a: PATO:0001301'
    lexer = OboParser::Lexer.new(input)
    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'id', t.tag
    assert_equal 'PATO:0000015', t.value

    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'name', t.tag
    assert_equal 'color hue', t.value

    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'def', t.tag
    assert_equal 'A chromatic scalar-circular quality inhering in an object that manifests in an observer by virtue of the dominant wavelength of the visible light; may be subject to fiat divisions, typically into 7 or 8 spectra.', t.value
    assert_equal(['PATOC:cjm'], t.xrefs) 

    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'subset', t.tag
    assert_equal 'attribute_slim', t.value

    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'is_a', t.tag
    assert_equal 'PATO:0001301', t.value
  end

  def test_typdef
     input = '[Typedef]
     id: part_of
     name: part of
     is_transitive: true'
     assert foo = parse_obo_file(input)
     assert_equal 1, foo.typedefs.size
     assert_equal 'part_of', foo.typedefs.first.id.value
  end

  def test_parse_term_stanza2
    input = '[Term]
      id: CL:0000009
      name: fusiform initial
      alt_id: CL:0000274
      def: "An elongated cell with approximately wedge-shaped ends, found in the vascular cambium, which gives rise to the elements of the axial system in the secondary vascular tissues." [ISBN:0471245208]
      synonym: "xylem initial" RELATED []
      synonym: "xylem mother cell" RELATED []
      is_a: CL:0000272 ! cambial initial
      is_a: CL:0000610 ! plant cell'

    assert foo = parse_obo_file(input)
    assert_equal 2, foo.terms.first.tags_named('synonym').size 
    assert_equal 'xylem initial', foo.terms.first.tags_named('synonym').first.value
    assert_equal 'xylem mother cell', foo.terms.first.tags_named('synonym')[1].value
    assert_equal 'CL:0000274', foo.terms.first.tags_named('alt_id').first.value

    assert_equal 2, foo.terms.first.relationships.size 
    assert_equal(['CL:0000272', 'CL:0000610'], foo.terms.first.relationships.collect{|r| r[1]}.sort)
    assert_equal(['is_a', 'is_a'], foo.terms.first.relationships.collect{|r| r[0]}.sort)

  end

  def test_parse_term
    lexer = OboParser::Lexer.new("[Term]")
    assert lexer.pop(OboParser::Tokens::Term)
  end

  def test_xref_list
    lexer = OboParser::Lexer.new("[foo:bar, stuff:things]") 
    assert t = lexer.pop(OboParser::Tokens::XrefList)
    assert_equal( {'foo' => 'bar', 'stuff' => 'things'} , t.value)
  end

  def test_relationship_tag
    lexer = OboParser::Lexer.new("relationship: develops_from CL:0000333 ! neural crest cell") 
    assert t = lexer.pop(OboParser::Tokens::RelationshipTag)
    assert_equal 'develops_from', t.relation
    assert_equal 'CL:0000333', t.related_term
    assert_equal 'relationship', t.tag

    lexer = OboParser::Lexer.new("relationship: develops_from CL:0000333") 
    assert t = lexer.pop(OboParser::Tokens::RelationshipTag)
    assert_equal 'develops_from', t.relation
    assert_equal 'CL:0000333', t.related_term
    assert_equal 'relationship', t.tag
  
    lexer = OboParser::Lexer.new("is_a: CL:0000333 ! Foo") 
    assert t = lexer.pop(OboParser::Tokens::IsATag)
    assert_equal 'is_a', t.relation
    assert_equal 'CL:0000333', t.related_term
    assert_equal 'Foo', t.comment

    lexer = OboParser::Lexer.new("disjoint_from: CL:0000333") 
    assert t = lexer.pop(OboParser::Tokens::DisjointFromTag)
    assert_equal 'disjoint_from', t.relation
    assert_equal 'CL:0000333', t.related_term
    assert_equal "", t.comment

    lexer = OboParser::Lexer.new("relationship: part_of CL:0000333 ! Foo") 
    assert t = lexer.pop(OboParser::Tokens::RelationshipTag)
    assert_equal 'part_of', t.relation
    assert_equal 'CL:0000333', t.related_term
    assert_equal 'Foo', t.comment

  end

  

  def test_tagvaluepair
    lexer = OboParser::Lexer.new("id: PATO:0000179")
    assert lexer.pop(OboParser::Tokens::TagValuePair)
  end

  def test_tagvaluepair_with_comments_and_xrefs
    lexer = OboParser::Lexer.new("def: \"The foo that is bar.\" [PATO:0000179] ! FOO! \n")
    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'def', t.tag
    assert_equal 'The foo that is bar.', t.value
    assert_equal 'FOO!', t.comment
    assert_equal(['PATO:0000179'], t.xrefs)
  end

  def test_that_synonyms_parse
    lexer = OboParser::Lexer.new("synonym: \"Nematoblast\" EXACT []\n")
    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'synonym', t.tag
    assert_equal 'Nematoblast', t.value
    assert_equal 'EXACT', t.qualifier
    assert_equal nil, t.comment
    assert_equal([], t.xrefs)
  end

  def test_that_xref_lists_parse_as_part_of_tagvalue_pair
    lexer = OboParser::Lexer.new('def: "Foo and the bar, and stuff, and things.  More stuff, and things!" [GO_REF:0000031 "Foo!" , GOC:msz {some=trailingmodifier}, GOC:tfm, ISBN:9780781765190 "Fundamental Immunology!, 6ed (Paul,ed), 2003", PMID:16014527] {qualifier=foo} ! and a comment')
    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'def', t.tag
    assert_equal 'Foo and the bar, and stuff, and things.  More stuff, and things!', t.value
    assert_equal(['GO_REF:0000031', 'GOC:msz', 'GOC:tfm', 'ISBN:9780781765190', 'PMID:16014527'], t.xrefs)
  end

  def test_crummy_space_filled_xrefs
    lexer = OboParser::Lexer.new('def: "A quality inhering in a bearer by virtue of emitting light during exposure to radiation from an external source." [The Free Online dictionary:The Free Online dictionary "www.thefreedictionary.com/ -"]')
    assert t = lexer.pop(OboParser::Tokens::TagValuePair)
    assert_equal 'def', t.tag
    assert_equal 'A quality inhering in a bearer by virtue of emitting light during exposure to radiation from an external source.', t.value
    assert_equal(['The Free Online dictionary:The Free Online dictionary'], t.xrefs)
  end

end

class Test_Parser < Test::Unit::TestCase
  def setup
    @of = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../test/obo_1.0_test.txt')) )
  end

  def test_file_parsing
    foo = parse_obo_file(@of)
    assert_equal 'pato', foo.terms[0].name.value
    assert_equal 'quality', foo.terms[1].name.value
    assert_equal 'part_of', foo.typedefs.last.name.value
    assert_equal 'OBO_REL:part_of', foo.typedefs.last.id.value
    assert_equal(['PATOC:GVG'], foo.terms[1].def.xrefs)
    assert_equal 'is_obsolete', foo.terms.first.tags_named('is_obsolete').first.tag
    assert_equal 'true', foo.terms.first.tags_named('is_obsolete').first.value
  end

  def test_complex_file_parsing
    assert of = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../test/cell.obo')) )
    foo = parse_obo_file(of)
    assert_equal 'cell', foo.terms.first.name.value
    assert_equal 'primary cell line cell', foo.terms[1].name.value

    tmp = foo.terms[9].tags_named('synonym')
    assert_equal 2, tmp.size
    assert_equal 'xylem initial', tmp.first.value
    assert_equal 'xylem mother cell', tmp[1].value
    assert_equal([], tmp[1].xrefs)

    assert_equal 2, foo.terms[9].relationships.size
  end

  def test_file_completes_without_typedefs
    @of2 = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../test/obo_1.0_test_wo_typedefs.txt')) )
    assert foo = parse_obo_file(@of2)
  end

  def teardown
    @of = nil
  end

end 

