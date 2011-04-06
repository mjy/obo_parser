module OboParser::Tokens

  class Token 
    # this allows access the the class attribute regexp, without using a class variable
    class << self; attr_reader :regexp; end
    attr_reader :value    
    def initialize(str)
      @value = str
    end
  end

  class Term < Token
    @regexp = Regexp.new(/\A\s*(\[term\])\s*/i)
  end

  class Typedef < Token
    @regexp = Regexp.new(/\A\s*(\[typedef\])\s*/i)
  end

  class TagValuePair < Token
    attr_reader :tag, :comment, :xrefs, :qualifier
    @regexp = Regexp.new(/\A\s*([^:]+:.+)\s*\n*/i) 
    def initialize(str)
      str.strip!
      tag, value = str.split(':',2)      
      @tag = tag.strip

      value.strip!

      # Handle comments 
      if value =~ /(!\s*.+)\Z/i
        @comment = $1
        value.gsub!(@comment, '')
        @comment.gsub!(/\A!\s*/, '')
      end 

      # Break out the xrefs, could be made made robust 
      # Assumes non-quoted comma delimited in format 'foo:bar, stuff:things'
      if value =~ /(\s*\[.*\]\s*)/i 
        xref_list = $1
        value.gsub!(xref_list, '')
        xref_list.strip!
        xref_list = xref_list[1..-2] # strip []
        @xrefs = xref_list.split(",") 
      end

      if value =~ /\A\"/
        value =~ /(".*")/
        @value = $1
        value.gsub!(@value, '')
        @qualifier = value.strip
      else
        @value = value.strip
        @qualifier = nil
      end

      @value = @value[1..-2].strip if @value[0..0] == "\"" # get rid of quote marks
      @value = @value[1..-2].strip if @value[0..0] == "'"  # get rid of quote marks
    end
  end

  class XrefList < Token
    @regexp = Regexp.new(/\A\s*\[(.+)\]\s*\n*/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
    def initialize(str)
      str.strip!
      @value = {}
      str.split(",").each do |s| 
        i = s.split(":")
        @value.merge!(i[0].strip => i[1].strip)
      end
    end
  end

  class NameValuePair < Token
    @regexp = Regexp.new('fail')
  end

  class Dbxref < Token
    @regexp = Regexp.new('fail')
  end

  # same as ID
  class Label < Token
    @regexp = Regexp.new('\A\s*((\'+[^\']+\'+)|(\"+[^\"]+\"+)|(\w[^,:(); \t\n]*|_)+)\s*') #  matches "foo and stuff", foo, 'stuff or foo', '''foo''', """bar""" BUT NOT ""foo" "
    def initialize(str)
      str.strip!
      str = str[1..-2] if str[0..0] == "'" # get rid of quote marks
      str = str[1..-2] if str[0..0] == '"' 
      str.strip! 
      @value = str
    end
  end

  # note we grab EOL and ; here 
  class ValuePair < Token
    @regexp = Regexp.new(/\A\s*([\w\d\_\&]+\s*=\s*((\'[^\']+\')|(\(.*\))|(\"[^\"]+\")|([^\s\n\t;]+)))[\s\n\t;]+/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
    def initialize(str)
      str.strip!
      str = str.split(/=/)
      str[1].strip!
      str[1] = str[1][1..-2] if str[1][0..0] == "'" 
      str[1] = str[1][1..-2] if str[1][0..0] ==  "\"" 
      @value = {str[0].strip.downcase.to_sym => str[1].strip}
    end
  end

  class EndOfFile < Token
    @regexp = Regexp.new('\A(\s*\n*)\Z')
  end

  ## punctuation

  class LBracket < Token
    @regexp = Regexp.new('\A\s*(\[)\s*')
  end

  #class LParen < Token
  #  @regexp = Regexp.new('\A\s*(\()\s*')
  #end
  
  #class RBracket < Token
  #  @regexp = Regexp.new('\A\s*(\])\s*')
  #end
  
  #class RParen < Token
  #  @regexp = Regexp.new('\A\s*(\))\s*')
  #end
  
  #class Equals < Token
  #  @regexp = Regexp.new('\A\s*(=)\s*')
  #end
  
  #class BckSlash < Token
  #  @regexp = Regexp.new('\A\s*(\/)\s*')
  #end
  
  #class Colon < Token
  #  @regexp = Regexp.new('\A\s*(:)\s*')
  #end
  
  #class SemiColon < Token
  #  @regexp = Regexp.new('\A\s*(;)\s*')
  #end
  
  #class Comma < Token
  #  @regexp = Regexp.new('\A\s*(\,)\s*')
  #end
 
  #class Number < Token
  #  @regexp = Regexp.new('\A\s*(-?\d+(\.\d+)?([eE][+-]?\d+)?)\s*')
  #  def initialize(str)
  #    # a little oddness here, in some case we don't want to include the .0
  #    # see issues with numbers as labels
  #    if str =~ /\./
  #      @value = str.to_f
  #    else
  #      @value = str.to_i
  #    end
  #  end
  #end

  # This list defines inclusion and priority, i.e. if tokens have overlap then the earlier indexed token will match first
  def self.obo_file_token_list
    [ 
      OboParser::Tokens::Term,
      OboParser::Tokens::Typedef,
      OboParser::Tokens::LBracket,
      OboParser::Tokens::TagValuePair,
      OboParser::Tokens::XrefList,
      OboParser::Tokens::EndOfFile
      # OboParser::Tokens::NameValuePair,  # not implemented
      # OboParser::Tokens::Dbxref,         # not implemented
    ]   
  end

end
