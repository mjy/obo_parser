require 'spec_helper'

describe OboParser do

  context 'test builder' do
    specify 'can be #new' do
      expect( OboParser::OboParserBuilder.new).to be_truthy
    end
  end

  context 'lexer' do
    specify 'term' do
      lexer = OboParser::Lexer.new('[Term]')
      expect(lexer.pop(OboParser::Tokens::Term)).to be_truthy
    end

    context 'end_of_file' do
      specify 'one' do
        lexer = OboParser::Lexer.new("    \n\n")
        expect(lexer.pop(OboParser::Tokens::EndOfFile)).to be_truthy
      end

      specify 'two' do
        lexer = OboParser::Lexer.new("\n")
        expect(lexer.pop(OboParser::Tokens::EndOfFile)).to be_truthy
      end
    end

    context 'parse_term_stanza' do
      let(:input) { '
        id: PATO:0000015
        name: color hue
        def: "A chromatic scalar-circular quality inhering in an object that manifests in an observer by virtue of the dominant wavelength of the visible light; may be subject to fiat divisions, typically into 7 or 8 spectra." [PATOC:cjm]
        subset: attribute_slim
        is_a: PATO:0001301'
      }
      let(:lexer) { OboParser::Lexer.new(input) } 

      specify 'pop a number of values off' do
        expect(t = lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
        expect(t.tag).to eq('id')
        expect(t.value).to eq('PATO:0000015')
      
        expect(t = lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
        expect(t.tag).to eq('name')
        expect(t.value).to eq('color hue')

        expect(t = lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
        expect(t.tag).to eq('def')
        expect(t.value).to eq('A chromatic scalar-circular quality inhering in an object that manifests in an observer by virtue of the dominant wavelength of the visible light; may be subject to fiat divisions, typically into 7 or 8 spectra.')
        expect(t.xrefs).to eq(['PATOC:cjm']) 

        expect(t = lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
        expect(t.tag).to eq('subset')
        expect(t.value).to eq('attribute_slim')

        expect(t = lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
        expect(t.tag).to eq('is_a')
        expect(t.value).to eq('PATO:0001301')
      end
    end

    context 'typdef' do
      let(:input) {'[Typedef]
       id: part_of
       name: part of
       is_transitive: true'
      }

      specify 'parses' do
        expect(foo = parse_obo_file(input)).to be_truthy
        expect(foo.typedefs.size).to eq(1)
        expect(foo.typedefs.first.id.value).to eq('part_of')
      end
    end

    context 'parse_term_stanza2' do
      let(:input) {'[Term]
      id: CL:0000009
      name: fusiform initial
      alt_id: CL:0000274
      def: "An elongated cell with approximately wedge-shaped ends, found in the vascular cambium, which gives rise to the elements of the axial system in the secondary vascular tissues." [ISBN:0471245208]
      synonym: "xylem initial" RELATED []
      synonym: "xylem mother cell" RELATED []
      is_a: CL:0000272 ! cambial initial
      is_a: CL:0000610 ! plant cell'
      }

      specify 'parsing' do
        expect( t = parse_obo_file(input)).to be_truthy
        expect( t.terms.first.tags_named('synonym').size).to eq(2) 
        expect( t.terms.first.tags_named('synonym').first.value).to eq('xylem initial') 
        expect( t.terms.first.tags_named('synonym')[1].value ).to eq('xylem mother cell')
        expect( t.terms.first.tags_named('alt_id').first.value).to eq('CL:0000274')

        expect( t.terms.first.relationships.size ).to eq(2)
        expect( t.terms.first.relationships.collect{|r| r[1]}.sort).to contain_exactly('CL:0000272', 'CL:0000610')
        expect( t.terms.first.relationships.collect{|r| r[0]}.sort).to contain_exactly( 'is_a', 'is_a')
      end

      specify 'parse_term' do
        lexer = OboParser::Lexer.new("[Term]")
        expect(lexer.pop(OboParser::Tokens::Term)).to be_truthy
      end

      specify 'xref_list' do
        lexer = OboParser::Lexer.new("[foo:bar, stuff:things]") 
        expect(t = lexer.pop(OboParser::Tokens::XrefList)).to be_truthy
        expect(t.value).to eq({'foo' => 'bar', 'stuff' => 'things'})
      end
    end

    context 'relationship_tag' do
      specify '1' do
        lexer = OboParser::Lexer.new("relationship: develops_from CL:0000333 ! neural crest cell") 
        expect(t = lexer.pop(OboParser::Tokens::RelationshipTag)).to be_truthy
        expect(t.relation).to eq('develops_from')
        expect(t.related_term).to eq( 'CL:0000333') 
        expect(t.tag).to eq('relationship')
      end

      specify '2' do
        lexer = OboParser::Lexer.new("relationship: develops_from CL:0000333") 
        expect(t = lexer.pop(OboParser::Tokens::RelationshipTag)).to be_truthy
        expect(t.relation).to eq('develops_from')
        expect(t.related_term).to eq( 'CL:0000333') 
        expect(t.tag).to eq('relationship')
      end

      specify '3 IsATag' do
        lexer = OboParser::Lexer.new("is_a: CL:0000333 ! Foo") 
        expect(t = lexer.pop(OboParser::Tokens::IsATag)).to be_truthy
        expect(t.relation).to eq('is_a')
        expect(t.related_term).to eq( 'CL:0000333') 
        expect(t.comment).to eq('Foo')
      end

      specify '4 DisjointFromTag' do
        lexer = OboParser::Lexer.new("disjoint_from: CL:0000333") 
        expect(t = lexer.pop(OboParser::Tokens::DisjointFromTag)).to be_truthy
        expect(t.relation).to eq('disjoint_from')
        expect(t.related_term).to eq( 'CL:0000333') 
        expect(t.comment).to eq('')
      end

      specify '4 RelationshipTag' do
        lexer = OboParser::Lexer.new("relationship: part_of CL:0000333 ! Foo") 
        expect(t = lexer.pop(OboParser::Tokens::RelationshipTag)).to be_truthy
        expect(t.relation).to eq('part_of')
        expect(t.related_term).to eq( 'CL:0000333') 
        expect(t.comment).to eq('Foo')
      end

      specify 'tagvaluepair' do
        lexer = OboParser::Lexer.new("id: PATO:0000179")
        expect( lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
      end

      specify 'tagvaluepair_with_comments_and_xrefs' do
        lexer = OboParser::Lexer.new("def: \"The foo that is bar.\" [PATO:0000179] ! FOO! \n")
        expect( t = lexer.pop(OboParser::Tokens::TagValuePair) ).to be_truthy
        expect( t.tag).to eq( 'def' )
        expect( t.value).to eq( 'The foo that is bar.')
        expect( t.comment).to eq( 'FOO!' )
        expect( t.xrefs).to eq( ['PATO:0000179'] ) 
      end

      specify 'tagvaluepair_with_comments_and_xrefs' do
        lexer = OboParser::Lexer.new("def: \"The foo that is bar.\" [PATO:0000179] ! FOO! \n")
        expect( t = lexer.pop(OboParser::Tokens::TagValuePair) ).to be_truthy 
        expect( t.tag).to eq('def')
        expect( t.value).to eq( 'The foo that is bar.' )
        expect( t.comment).to eq( 'FOO!' )
        expect( t.xrefs).to eq( ['PATO:0000179'] )
      end

      specify 'that_synonyms_parse' do
        lexer = OboParser::Lexer.new("synonym: \"Nematoblast\" EXACT []\n")
        expect(t = lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
        expect(t.tag).to eq('synonym')
        expect(t.value).to eq('Nematoblast')
        expect(t.qualifier).to eq('EXACT')
        expect(t.comment).to eq(nil)
        expect(t.xrefs).to eq([])
      end

      specify 'that_xref_lists_parse_as_part_of_tagvalue_pair' do
        lexer = OboParser::Lexer.new('def: "Foo and the bar, and stuff, and things.  More stuff, and things!" [GO_REF:0000031 "Foo!" , GOC:msz {some=trailingmodifier}, GOC:tfm, ISBN:9780781765190 "Fundamental Immunology!, 6ed (Paul,ed), 2003", PMID:16014527] {qualifier=foo} ! and a comment')
        expect( t = lexer.pop(OboParser::Tokens::TagValuePair) ).to be_truthy
        expect(t.tag).to eq('def')
        expect(t.value).to eq('Foo and the bar, and stuff, and things.  More stuff, and things!')
        expect(t.xrefs).to eq(['GO_REF:0000031', 'GOC:msz', 'GOC:tfm', 'ISBN:9780781765190', 'PMID:16014527'])
      end

      specify 'crummy_space_filled_xrefs' do
        lexer = OboParser::Lexer.new('def: "A quality inhering in a bearer by virtue of emitting light during exposure to radiation from an external source." [The Free Online dictionary:The Free Online dictionary "www.thefreedictionary.com/ -"]')
        expect(t = lexer.pop(OboParser::Tokens::TagValuePair)).to be_truthy
        expect(t.tag).to eq('def')
        expect(t.value).to eq( 'A quality inhering in a bearer by virtue of emitting light during exposure to radiation from an external source.')
        expect(t.xrefs).to eq(['The Free Online dictionary:The Free Online dictionary'])
      end
    end
  end

  context 'Test_Parse' do
    let(:of) { File.read(File.expand_path(File.join(File.dirname(__FILE__), '../files/obo_1.0_test.txt')) ) }
    let(:foo) { parse_obo_file(of) }

    specify 'file_parsing' do
      expect(foo.terms[0].name.value).to eq( 'pato') 
      expect(foo.terms[1].name.value).to eq('quality') 
      expect(foo.typedefs.last.name.value).to eq('part_of') 
      expect( foo.typedefs.last.id.value).to eq(  'OBO_REL:part_of')
      expect( foo.terms[1].def.xrefs).to eq(['PATOC:GVG'])
      expect( foo.terms.first.tags_named('is_obsolete').first.tag).to eq('is_obsolete') 
      expect( foo.terms.first.tags_named('is_obsolete').first.value).to eq('true') 
    end
  end

  context 'complex_file_parsing' do
    let(:of) { File.read(File.expand_path(File.join(File.dirname(__FILE__), '../files/cell.obo')) ) }
    let(:foo) { parse_obo_file(of) } 

    specify 'complex_file_parsing' do
      expect(foo.terms.first.name.value).to eq( 'cell' ) 
      expect(foo.terms[1].name.value).to eq('primary cell line cell')
      tmp = foo.terms[9].tags_named('synonym')
      expect(tmp.size).to eq(2)
      expect(tmp.first.value).to eq('xylem initial')
      expect(tmp[1].value).to eq( 'xylem mother cell' )
      expect(tmp[1].xrefs).to eq([])
      expect(foo.terms[9].relationships.size).to eq(2)
    end
  end

  specify 'complex_file_parsing_2' do
    expect(of = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../files/hao.obo')) )).to be_truthy
    foo = parse_obo_file(of)
    expect(foo.terms.first.name.value).to eq('anatomical entity')
    expect(foo.terms[1].name.value).to eq('ventral mesofurco-profurcal muscle')
  end

  specify 'complex_file_parsing_3' do
    expect(of = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../files/tgma.obo')) ) ).to be_truthy
    expect(foo = parse_obo_file(of)).to be_truthy

    # assert_equal 'anatomical entity', foo.terms.first.name.value
    # assert_equal 'ventral mesofurco-profurcal muscle', foo.terms[1].name.value

    #tmp = foo.terms[9].tags_named('synonym')
    #assert_equal 2, tmp.size
    #assert_equal 'xylem initial', tmp.first.value
    #assert_equal 'xylem mother cell', tmp[1].value
    #assert_equal([], tmp[1].xrefs)

    #assert_equal 2, foo.terms[9].relationships.size
  end

  specify 'complex_file_parsing4' do
    expect(of = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../files/go.obo')) )).to be_truthy
    expect(foo = parse_obo_file(of)).to be_truthy
    expect(foo.terms.first.name.value).to eq( 'hemolymph')
    expect( foo.terms[1].name.value).to eq('hemocyte')
    expect( foo.terms.first.relationships.size).to eq(1)
  end

  specify 'file_completes_without_typedefs' do
    expect(of2 = File.read(File.expand_path(File.join(File.dirname(__FILE__), '../files/obo_1.0_test_wo_typedefs.txt')) )).to be_truthy
    expect(foo = parse_obo_file(of2)).to be_truthy
  end

end
