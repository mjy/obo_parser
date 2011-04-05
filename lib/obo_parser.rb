# uses the PhyloTree parser/lexer engine by Krishna Dole which in turn was based on
# Thomas Mailund's <mailund@birc.dk> 'newick-1.0.5' Python library

#== Outstanding issues:
# * Better documentation
# * More tests

module OboParser

  require File.expand_path(File.join(File.dirname(__FILE__), 'tokens'))
  require File.expand_path(File.join(File.dirname(__FILE__), 'parser'))
  require File.expand_path(File.join(File.dirname(__FILE__), 'lexer'))
  require File.expand_path(File.join(File.dirname(__FILE__), 'utilities'))

  class OboParser 
    attr_accessor :terms, :typedefs

    def initialize 
      @terms = []
      @typedefs = [] 
      true
    end

    def term_strings # :yields: Array of Strings
      @terms.collect{|t| t.name.value}.sort
    end

    # Warning! This assumes terms are unique, they are NOT required to be so in an OBO file.
    def term_hash # :yields: Hash (String => String) (name => id)
      @terms.inject({}) {|sum, t| sum.update(t.name.value => t.id.value)}
    end

    def id_hash # :yields: Hash (String => String (id => name))
      @terms.inject({}) {|sum, t| sum.update(t.id.value => t.name.value)}
    end

    class Stanza
      # Make special reference to several specific types of tags (:name, :id), subclasses will remove additional special typs from :other_tags
      attr_accessor :name, :id, :def, :other_tags

      def initialize(tags)
        @other_tags = []

        while tags.length != 0
          t = tags.shift

          new_tag = OboParser::Tag.new
          new_tag.tag = t.tag
          new_tag.value = t.value
          new_tag.comment = t.comment
          new_tag.xrefs = t.xrefs

          case new_tag.tag
          when 'id' 
            @id = new_tag
          when 'name'
            @name = new_tag
          when 'def'
            @def = new_tag
          else
            @other_tags.push(new_tag)
          end
        end
      end

      #=== Convienience methods

      def tags_named(tag_name = nil)
        return nil if tag_name.nil?
        result = []
        @other_tags.each do |t|
          result.push t if t.tag == tag_name
        end
        result
      end

    end

    # TODO: likely deprecate and run with one model (Stanza)
    class Term < Stanza
  #   attr_accessor :some_term_specific_def
      def initialize(tags)
        super
  #     anonymous_tags = [] 
  #     # Loop through "unclaimed" tags and reference those specific to Term
  #     while @other_tags.size != 0
  #       t = @other_tags.shift
  #       case t.tag
  #       when 'def' 
  #         @def = t
  #       else
  #         anonymous_tags.push(t)
  #       end
  #     end
  #     @other_tags = anonymous_tags
      end
    end

    class Typedef < Stanza
      def initialize(tags)
        super
        #anonymous_tags = [] 
        ## Loop through "unclaimed" tags and reference those specific to Typedef
        #while @other_tags.size != 0
        #  t = @other_tags.shift
        #  case t.tag
        #  when 'def' 
        #    @def = t
        #  else
        #    anonymous_tags.push(t)
        #  end
        #  @other_tags = anonymous_tags
        #end
      end
    end

    class Tag
      attr_accessor :tag, :value, :xrefs, :comment
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

#= Implementation

def parse_obo_file(input)
  @input = input
  raise(OboParser::ParseError, "Nothing passed to parse!") if !@input || @input.size == 0

  # Comments are handled now.
  # @input.gsub!(/(\s*?![^!'"]*?\n)/i, "\n")  # strip out comments - this is a kludge, likely needs fixing!!

  builder = OboParser::OboParserBuilder.new
  lexer = OboParser::Lexer.new(@input)
  OboParser::Parser.new(lexer, builder).parse_file
  return builder.obo_file  
end
