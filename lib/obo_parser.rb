
# uses the PhyloTree parser/lexer engine by Krishna Dole which in turn was based on
# Thomas Mailund's <mailund@birc.dk> 'newick-1.0.5' Python library

# outstanding issues:

module OboParser

require File.expand_path(File.join(File.dirname(__FILE__), 'tokens'))
require File.expand_path(File.join(File.dirname(__FILE__), 'parser'))
require File.expand_path(File.join(File.dirname(__FILE__), 'lexer'))
require File.expand_path(File.join(File.dirname(__FILE__), 'utilities'))


class OboParser # Node
  attr_accessor :terms, :typedefs

  def initialize
    @terms = []
    @typedefs = [] 
  end

  def term_strings
    @terms.collect{|t| t.name}.sort
  end

  # assumes terms are unique! 
  def term_hash
    @terms.inject({}) {|sum, t| sum.update(t.name => t.id)}
  end

  # ids are unique
  def id_hash
    @terms.inject({}) {|sum, t| sum.update(t.id => t.name)}
  end

  class Stanza
    attr_accessor :name, :id, :tags
    # we can have only one of id, name, and some others (but this is a loose setup now)
    # can have many of some other things- put them in tags
    
    def initialize(tags)
      @tags = {}
      tags.each do |t|
        case t[0]
        when 'id' 
          @id = t[1] 
        when 'name'
          @name = t[1]
        else
          @tags[t[0]] = [] if !@tags[t[0]] 
          @tags[t[0]].push t[1]
        end
      end
    end
  end

  class Term < Stanza
    attr_accessor :def
    def initialize(tags)
      super
    end
  end

  class Typedef < Stanza
    def initialize(tags)
      super
    end
  end

end


class OboParserBuilder
  def initialize
    @of =  OboParser.new 
  end

  def add_term(tags)
    @of.terms.push OboParser::Term.new(tags)
  end

  def add_typedef(tags)
    @of.typedefs.push OboParser::Typedef.new(tags)
  end

  def obo_file
    @of
  end

end

class ParseError < StandardError
end

end # end module

# the actual method
def parse_obo_file(input)
  @input = input
   raise(OboParser::ParseError, "Nothing passed to parse!") if  !@input ||  @input.size == 0

  @input.gsub!(/(\s*?![^!'"]*?\n)/i, "\n")  # strip out comments - this is a kludge, likely needs fixing!!
    
  builder = OboParser::OboParserBuilder.new
  lexer = OboParser::Lexer.new(@input)
  OboParser::Parser.new(lexer, builder).parse_file
  return builder.obo_file  
end




