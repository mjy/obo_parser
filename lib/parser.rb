class OboParser::Parser
  def initialize(lexer, builder)
    @lexer = lexer
    @builder = builder
  end

  def parse_file
    # toss everything right now, we just want the terms
    while !@lexer.peek(OboParser::Tokens::Term)
      @lexer.pop(OboParser::Tokens::TagValuePair)
    end

    i = 0
    while !@lexer.peek(OboParser::Tokens::Typedef) && !@lexer.peek(OboParser::Tokens::EndOfFile)
      raise OboParser::ParseError, "infinite loop in Terms" if i > 10000000 
      parse_term
      i += 1
    end

    i = 0
    while @lexer.peek(OboParser::Tokens::Typedef) 
      raise OboParser::ParseError,"infinite loop in Terms" if i > 1000000 # there aren't that many words!
      parse_typedef
      i += 1
    end    
  end

  def parse_term
    t = @lexer.pop(OboParser::Tokens::Term)
    tags = []
    while !@lexer.peek(OboParser::Tokens::Term) && !@lexer.peek(OboParser::Tokens::Typedef) && !@lexer.peek(OboParser::Tokens::EndOfFile) 
      if @lexer.peek(OboParser::Tokens::TagValuePair)
        t = @lexer.pop(OboParser::Tokens::TagValuePair)
        tags.push [t.tag, t.value]
      else
        raise(OboParser::ParseError, "Expected a tag-value pair, but did not get one following this tag/value: [#{t.tag} / #{t.value}]")
      end
    end
    @builder.add_term(tags)
  end

  def parse_typedef
    @lexer.pop(OboParser::Tokens::Typedef)
    #  @t = @builder.stub_typdef
    tags = []
    while !@lexer.peek(OboParser::Tokens::Typedef) && @lexer.peek(OboParser::Tokens::TagValuePair)
      t = @lexer.pop(OboParser::Tokens::TagValuePair)
      tags.push [t.tag, t.value]
    end
    @builder.add_typedef(tags)
  end

end
