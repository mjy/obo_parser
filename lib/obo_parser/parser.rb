class OboParser::Parser
  def initialize(lexer, builder)
    @lexer = lexer
    @builder = builder
  end

  def parse_file
    # At present we ignore the header lines
    while !@lexer.peek(OboParser::Tokens::Term) && !@lexer.peek(OboParser::Tokens::Typedef)
      @lexer.pop(OboParser::Tokens::TagValuePair)
    end

    i = 0
    while !@lexer.peek(OboParser::Tokens::Typedef) && !@lexer.peek(OboParser::Tokens::EndOfFile)
      raise OboParser::ParseError, "infinite loop in Terms?" if i > 20000 # there aren't that many words! 
      parse_term
      i += 1
    end

    i = 0
    while @lexer.peek(OboParser::Tokens::Typedef) 
      raise OboParser::ParseError,"infinite loop in Typedefs?" if i > 20000 
      parse_typedef
      i += 1
    end    

  end

  def parse_term
    t = @lexer.pop(OboParser::Tokens::Term)
    tags = []
    while !@lexer.peek(OboParser::Tokens::Term) && !@lexer.peek(OboParser::Tokens::Typedef) && !@lexer.peek(OboParser::Tokens::EndOfFile) 
      begin
        
        if @lexer.peek(OboParser::Tokens::IsATag) 
          t = @lexer.pop(OboParser::Tokens::IsATag)
        elsif @lexer.peek(OboParser::Tokens::DisjointFromTag) 
          t = @lexer.pop(OboParser::Tokens::DisjointFromTag)
        elsif @lexer.peek(OboParser::Tokens::RelationshipTag) 
          t = @lexer.pop(OboParser::Tokens::RelationshipTag)
        else 
          t = @lexer.pop(OboParser::Tokens::TagValuePair)
        end
        tags.push(t) 

      rescue 
        raise 
      end
    end
    @builder.add_term(tags)
  end

  def parse_typedef
    @lexer.pop(OboParser::Tokens::Typedef)
    tags = []
    while !@lexer.peek(OboParser::Tokens::Typedef) && @lexer.peek(OboParser::Tokens::TagValuePair)
      begin
        t = @lexer.pop(OboParser::Tokens::TagValuePair)
        tags.push(t) 
      rescue
        raise 
      end
    end
    @builder.add_typedef(tags)
  end

end
