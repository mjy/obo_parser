module OboFile::Tokens

  class Token 
    # this allows access the the class attribute regexp, without using a class variable
    class << self; attr_reader :regexp; end
    attr_reader :value    
    def initialize(str)
      @value = str
    end
  end

  # in ruby, \A is needed if you want to only match at the beginning of the string, we need this everywhere, as we're
  # moving along popping off
 
  class Term < Token
    @regexp = Regexp.new(/\A\s*(\[term\])\s*/i)
  end

  class Typedef < Token
    @regexp = Regexp.new(/\A\s*(\[typedef\])\s*/i)
  end


  class TagValuePair < Token
    attr_reader :tag, :value
    @regexp = Regexp.new(/\A\s*([^:]+:.+)\s*\n*/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
    def initialize(str)
      str.strip!
      str = str.split(':',2)      
      
      str[1].strip!
      # strip trailing comments

      @tag = str[0]
      @value = str[1]
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

  class Matrix < Token
    @regexp = Regexp.new(/\A\s*(matrix)\s*/i)
  end

  class RowVec < Token
    @regexp = Regexp.new(/\A\s*(.+)\s*\n/i)
     def initialize(str)
      s = str.split(/\(|\)/).collect{|s| s=~ /[\,|\s]/ ? s.split(/[\,|\s]/) : s}.inject([]){|sum, x| x.class == Array ? sum << x.delete_if {|y| y == "" } : sum + x.strip.split(//)}
      @value = s
    end
  end



  ## punctuation

  class LBracket < Token
    @regexp = Regexp.new('\A\s*(\[)\s*')
  end

  class RBracket < Token
    @regexp = Regexp.new('\A\s*(\])\s*')
  end

  class LParen < Token
      @regexp = Regexp.new('\A\s*(\()\s*')
  end

  class RParen < Token
    @regexp = Regexp.new('\A\s*(\))\s*')
  end
 
  class Equals < Token
    @regexp = Regexp.new('\A\s*(=)\s*')
  end

  class BckSlash < Token
    @regexp = Regexp.new('\A\s*(\/)\s*')
  end


  class Colon < Token
    @regexp = Regexp.new('\A\s*(:)\s*')
  end

  class SemiColon < Token
    @regexp = Regexp.new('\A\s*(;)\s*')
  end

  class Comma < Token
    @regexp = Regexp.new('\A\s*(\,)\s*')
  end

  class EndOfFile < Token
    @regexp = Regexp.new('\A(\s*\n*)\Z')
  end

  class Number < Token
    @regexp = Regexp.new('\A\s*(-?\d+(\.\d+)?([eE][+-]?\d+)?)\s*')
    def initialize(str)
      # a little oddness here, in some case we don't want to include the .0
      # see issues with numbers as labels
      if str =~ /\./
        @value = str.to_f
      else
        @value = str.to_i
      end

    end
  end

  # Tokens::NexusComment

  # this list also defines priority, i.e. if tokens have overlap (which they shouldn't!!) then the earlier indexed token will match first
  def self.obo_file_token_list
    [ 
      OboFile::Tokens::Term,
      OboFile::Tokens::Typedef,
      OboFile::Tokens::TagValuePair,
      OboFile::Tokens::NameValuePair,  # not implemented
      OboFile::Tokens::Dbxref,         # not implemented
      OboFile::Tokens::LBracket,
      OboFile::Tokens::EndOfFile
    ]   
  end
  
end
