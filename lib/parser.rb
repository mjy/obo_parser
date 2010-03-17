class OboFile::Parser
  def initialize(lexer, builder)
    @lexer = lexer
    @builder = builder
  end

  def parse_file
    # toss everything right now, we just want the terms
    while !@lexer.peek(OboFile::Tokens::Term)
      @lexer.pop(OboFile::Tokens::TagValuePair)
    end

    i = 0
    while !@lexer.peek(OboFile::Tokens::Typedef) && !@lexer.peek(OboFile::Tokens::EndOfFile)
      raise OboFile::ParseError, "infinite loop in Terms" if i > 10000000 
      parse_term
      i += 1
    end

    i = 0
    while @lexer.peek(OboFile::Tokens::Typedef) 
      raise OboFile::ParseError,"infinite loop in Terms" if i > 1000000 # there aren't that many words!
      parse_typedef
      i += 1
    end    
  end

  def parse_term
    t = @lexer.pop(OboFile::Tokens::Term)
    tags = []
    while !@lexer.peek(OboFile::Tokens::Term) && !@lexer.peek(OboFile::Tokens::Typedef) && !@lexer.peek(OboFile::Tokens::EndOfFile) 
      if @lexer.peek(OboFile::Tokens::TagValuePair)
        t = @lexer.pop(OboFile::Tokens::TagValuePair)
        tags.push [t.tag, t.value]
      else
        raise(OboFile::ParseError, "Expected a tag-value pair, but did not get one following this tag/value: [#{t.tag} / #{t.value}]")
      end
    end
    @builder.add_term(tags)
  end

  def parse_typedef
    @lexer.pop(OboFile::Tokens::Typedef)
    #  @t = @builder.stub_typdef
    tags = []
    while !@lexer.peek(OboFile::Tokens::Typedef) && @lexer.peek(OboFile::Tokens::TagValuePair)
      t = @lexer.pop(OboFile::Tokens::TagValuePair)
      tags.push [t.tag, t.value]
    end
    @builder.add_typedef(tags)
  end

end
