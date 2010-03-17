require 'test/unit'
require 'rubygems'
require 'ruby-debug'

require File.expand_path(File.join(File.dirname(__FILE__), '../lib/obo_file'))

class OboParserTest < Test::Unit::TestCase
  def test_truth
    assert true
  end
end

class Test_OboFileBuilder < Test::Unit::TestCase
  def test_builder
    b = OboFile::OboFileBuilder.new
  end
end


class Test_Regex < Test::Unit::TestCase

  def test_comment_stripping
    # hackish, likely will fail with complex combinations of "!"
    txt = "line without note\nBegin taxa; ! comment\n! not this line\n'this ok!'\n\"this too!!\""
    r2 = Regexp.new(/(\s*?![^!'"]*?\n)/i)
    assert_equal "line without note\nBegin taxa;\n\n'this ok!'\n\"this too!!\"" , txt.gsub(r2, "\n")    
  end
end

class Test_Lexer < Test::Unit::TestCase
  
  def test_term
     lexer = OboFile::Lexer.new("[Term]")
     assert lexer.pop(OboFile::Tokens::Term)
  end
  
  def test_end_of_file
     lexer = OboFile::Lexer.new("    \n\n")
     assert lexer.pop(OboFile::Tokens::EndOfFile)
  
     lexer = OboFile::Lexer.new("\n")
     assert lexer.pop(OboFile::Tokens::EndOfFile)
  end

  def test_parse_term_stanza
    input = '
      id: PATO:0000015
      name: color hue
      def: "A chromatic scalar-circular quality inhering in an object that manifests in an observer by virtue of the dominant wavelength of the visible light; may be subject to fiat divisions, typically into 7 or 8 spectra." [PATOC:cjm]
      subset: attribute_slim
      is_a: PATO:0001301'
    lexer = OboFile::Lexer.new(input)
    assert t = lexer.pop(OboFile::Tokens::TagValuePair)
    assert_equal 'id', t.tag
    assert_equal 'PATO:0000015', t.value

    assert t = lexer.pop(OboFile::Tokens::TagValuePair)
    assert_equal 'name', t.tag
    assert_equal 'color hue', t.value

    assert t = lexer.pop(OboFile::Tokens::TagValuePair)
    assert_equal 'def', t.tag
    assert_equal '"A chromatic scalar-circular quality inhering in an object that manifests in an observer by virtue of the dominant wavelength of the visible light; may be subject to fiat divisions, typically into 7 or 8 spectra." [PATOC:cjm]', t.value

    assert t = lexer.pop(OboFile::Tokens::TagValuePair)
    assert_equal 'subset', t.tag
    assert_equal 'attribute_slim', t.value

    assert t = lexer.pop(OboFile::Tokens::TagValuePair)
    assert_equal 'is_a', t.tag
    assert_equal 'PATO:0001301', t.value
  end


  def test_parse_term
     lexer = OboFile::Lexer.new("[Term]")
     assert lexer.pop(OboFile::Tokens::Term)
  end

  def test_tagvaluepair
     lexer = OboFile::Lexer.new("id: PATO:0000179")
     assert lexer.pop(OboFile::Tokens::TagValuePair)
  end
end

class Test_Parser < Test::Unit::TestCase
  def setup
    @of = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../test/obo_1.0_test.txt')) )
  end

  def test_file_parsing
    foo = parse_obo_file(@of)
    assert_equal 'pato', foo.terms[0].name
    assert_equal 'quality', foo.terms[1].name
    assert_equal 'part_of', foo.typedefs.last.name
    assert_equal 'OBO_REL:part_of', foo.typedefs.last.id
  end

  def teardown
    @of = nil
  end

  def test_file_completes_without_typedefs
    @of2 = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../test/obo_1.0_test_wo_typedefs.txt')) )
    assert foo = parse_obo_file(@of2)
  end

end 

