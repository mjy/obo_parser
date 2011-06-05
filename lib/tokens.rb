module OboParser::Tokens

  class Token 
    # this allows access the to class attribute regexp, without using a class variable
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

  # Token needs simplification, likely through creating additional tokens for quoted qualifiers, optional modifiers ({}), and the creation of individual
  # tokens for individual tags that don't conform to the pattern used for def: tags.
  # The code can't presently handle escaped characters (like \,), as bizzarely found in some OBO files.
  class TagValuePair < Token
    attr_reader :tag, :comment, :xrefs, :qualifier, :description
    @regexp = Regexp.new(/\A\s*([^:]+:.+)\s*\n*/i) 
    def initialize(str)
      str.strip!
      tag, value = str.split(':',2)      
      value.strip!

      if tag == 'comment'
        @tag = tag.strip
        @value = value.strip
        return
      end

      @xrefs = []

      # Handle inline comments  
      if value =~ /(\s+!\s*.+)\s*\n*\z/i
        @comment = $1
        value.gsub!(@comment, '')
        @comment.strip!
        @comment.gsub!(/\A!\s*/, '')
      end 

      value.strip!

      # Qualifier for the whole tag 
      if value =~ /(\{[^{]*?\})\s*\n*\z/
        @qualifier = $1
        value.gsub!(@qualifier, '')
        @qualifier.strip!
      end 

      value.strip!

      # Handle a xref list TODO: Tokenize
      if value =~ /(\[.*\])/i 
        xref_list = $1
        value.gsub!(xref_list, '')

        xref_list.strip!
        xref_list = xref_list[1..-2] # [] off

        qq = 0 # some failsafes
        while xref_list.length > 0
          qq += 1
          debugger if qq == 499
          raise "#{xref_list}" if qq > 500
          xref_list.gsub!(/\A\s*,\s*/, '')

          xref_list =~ /\A(.+?:[^\"|\{|\,]+)/i 
          v = $1

          if !(v == "") && !v.nil? 
            v.strip!
            r = Regexp.escape v 
            xref_list.gsub!(/\A#{r}\s*/, '')
            @xrefs.push(v) if !v.nil?
          end
         
          xref_list.strip!

          # A description
          if xref_list =~ /\A(\s*".*?")/i
            d = $1
            r = Regexp.escape d 
            xref_list.gsub!(/\A#{r}/, '') 
            xref_list.strip!
          end

          # A optional modifier
          if xref_list =~ /\A(\s*\{[^\}]*?\})/ 
            m = $1
            r = Regexp.escape m
            xref_list.gsub!(/\A#{r}/, '') 
            xref_list.strip!
          end

          xref_list.strip!
        end
      end

      value.strip!

      # At this point we still might have a '"foo" QUALIFIER' combination
      if value =~ /\A(\"[^\"]*\")\s+(.*)/
        @value = $1.strip
        @qualifier = $2.strip if !$2.nil?
      else
        @value = value.strip
      end
      
      @value = @value[1..-2].strip if @value[0..0] == "\"" 
      @tag = tag.strip
      @value.strip!
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

  class RelationshipTag < Token
    attr_reader :tag, :related_term, :relation, :comment, :xrefs #, :qualifier
    @regexp = Regexp.new(/\A\s*relationship:\s*(.+)\s*\n*/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
    def initialize(str)
      @tag = 'relationship'
      @xrefs = [] 
      @relation, @related_term = str.split(/\s/,3)
      
      str =~ /\s+!\s+(.*)\s*\n*/i
      @comment = $1

      @comment ||= ""
      [@relation, @related_term, @comment].map(&:strip!)
    end
  end

  class IsATag < Token
    attr_reader :tag, :related_term, :relation, :comment, :xrefs #, :qualifier
    @regexp = Regexp.new(/\A\s*is_a:\s*(.+)\s*\n*/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
    def initialize(str)
      @tag = 'relationship'
      @relation = 'is_a'
      @related_term, @comment = str.split(/\s/,2)
      @comment ||= ""
      @comment.gsub!(/\A!\s*/, '')
      [@relation, @related_term, @comment].map(&:strip!)
      @xrefs = [] 
    end
  end

  class DisjointFromTag < Token
    attr_reader :tag, :related_term, :relation, :comment, :xrefs #, :qualifier
    @regexp = Regexp.new(/\A\s*disjoint_from:\s*(.+)\s*\n*/i) #  returns key => value hash for tokens like 'foo=bar' or foo = 'b a ar'
    def initialize(str)
      @tag = 'relationship'
      @relation = 'disjoint_from'
      @related_term, @comment = str.split(/\s/,2)
      @comment ||= ""
      @comment.gsub!(/\A!\s*/, '')
      [@relation, @related_term, @comment].map(&:strip!)
      @xrefs = [] 
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
      OboParser::Tokens::DisjointFromTag,
      OboParser::Tokens::IsATag,
      OboParser::Tokens::RelationshipTag,
      OboParser::Tokens::TagValuePair,
      OboParser::Tokens::XrefList,
      OboParser::Tokens::EndOfFile
      # OboParser::Tokens::NameValuePair,  # not implemented
      # OboParser::Tokens::Dbxref,         # not implemented
    ]   
  end

end
