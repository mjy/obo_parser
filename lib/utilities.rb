require 'rubygems'
require 'byebug'
require File.expand_path(File.join(File.dirname(__FILE__), 'obo_parser')) 

module OboParser::Utilities

  # Summarizes labels used by id in a two column tab delimited format 
  # Providing a cutoff will report only those ids/labels with > 1 label per id
  # Does not (yet) include reference to synonyms, this could be easily extended.
  #
  #== Example use
  #		of1 = File.read('foo1.obo')	
  #		of2 = File.read('foo2.obo')	
  #		of3 = File.read('foo3.obo')	
  #		of4 = File.read('foo4.obo')	
  # 
  #  OboParser::Utilities.dump_comparison_by_id(0,[of1, of2, of3, of4])
  #
  # @param [Integer] cutoff only Term ids with > cutoff labels will be reported 
  # @param [Array] files an Array of read files 
  # @return [String] the translation in tab delimted format
  def self.dump_comparison_by_id(cutoff = 0, files = [])
    return '' if files.size < 1

    of = [] 
    files.each_with_index do |f, i|
      of[i] = parse_obo_file(f)	
    end

    all_data = {}

    of.each do |f|
      tmp_hash = f.id_hash
      tmp_hash.keys.each do |id|
        if all_data[id]
          all_data[id].push(tmp_hash[id])
        else
          all_data[id] = [tmp_hash[id]]
        end
      end
    end

    all_data.keys.sort.each do |k|
      if all_data[k].uniq.size > cutoff 
        puts "#{k}\t#{all_data[k].uniq.join(', ')}"
      end
    end
  end


  # Returns all labels found in all passed ontologies. Does not yet include synonyms.
  # Caution: strips adult, embryonic, larval from labels (comment to remove)
  #
  #== Example use
  #  of1 = File.read('fly_anatomy.obo')	
  #  of2 = File.read('hao.obo')	
  #  of3 = File.read('mosquito_anatomy.obo')	
  # 
  #  OboParser::Utilities.shared_labels([of1, of3])
  #
  # @param [Array] files an Array of read files 
  # @return [String] lables, one per line
  def self.shared_labels(files = []) 
    comparison = {}

    files.each do |f|
      o = parse_obo_file(f)
      o.term_hash.keys.each do |k|

        # TODO: make this optional 
        tmp = k.gsub(/adult/, "").strip
        tmp = k.gsub(/embryonic\/larval/, "").strip

        if comparison[tmp]
          comparison[tmp] += 1
        else
          comparison.merge!(tmp => 1)
        end
      end
    end

    match = [] 
    comparison.keys.each do |k|
      if comparison[k] == files.size 
        match.push k
      end
    end

    puts match.sort.join("\n")
    puts "\n#{match.length} total."

  end 

  #== Two column correspondances and translation tools

  HOMOLONTO_HEADER = %{
format-version: 1.2
auto-generated-by: obo_parser
default-namespace: fix_me

[Typedef]
id: OGEE:has_member
name: has_member
is_a: OBO_REL:relationship
def: "C has_member C', C is an homology group and C' is a biological object" []
comment: "We leave open the possibility that an homology group is a biological object. Thus, an homology group C may have C' has_member, with C' being an homology group."
is_transitive: true
is_anti_symmetric: true

}


  # Takes a two column input file, references it to two ontologies, and provides a report.
  #  
  #== Example use
  #  file = File.read('HAO_TGMA_list.txt')
  #  col1_obo = File.read('hao.obo')
  #  col2_obo = File.read('tgma.obo')
  #  
  #  OboParser::Utilities.column_translate(:data => file, :col1_obo => col1_obo, :col2_obo => col2_obo, :output => :homolonto)
  #== Output types
  # There are several output report types
  #   :xls - Translates the columns in the data_file to the option passed in :translate_to, the first matching against col1_obo, the second against col2_obo.  Returns an Excel file.
  #   :homolonto - Generates a homolonto compatible file to STDOUT
  #   :cols - Prints a two column format to STDOUT
  #
  # @param [Hash] options options.
  # @param [Symbol] data the two column data file.
  # @return [String] the transation in tab delimted format.
  def self.column_translate(options = {})
    opt = {
      :data => nil,
      :col1_obo => nil,
      :col2_obo => nil,
      :translate_to => :id,        # also :label
      :output => :cols,            # also :xls, :homolonto, :parent_match
      :parent_match_to => :is_a,   # only used when :output == :parent_match
      :output_filename => 'foo',
      :index_start => 0
    }.merge!(options)

    c1obo = parse_obo_file(opt[:col1_obo])
    c2obo = parse_obo_file(opt[:col2_obo])

    case opt[:output]
    when :xls
      Spreadsheet.client_encoding = 'UTF-8'
      book = Spreadsheet::Workbook.new
      sheet = book.create_worksheet
    when :homolonto
      s = HOMOLONTO_HEADER
      opt[:translate_to] = :id # force this in this mode
    end

    i = opt[:index_start]
    v1 = nil # a label like 'head'
    v2 = nil
    c1 = nil # an id 'FOO:123'
    c2 = nil

    opt[:data].split(/\n/).each do |row|
      i += 1
      c1, c2 =  row.split(/\t/).map(&:strip)

      if c1.nil? || c2.nil?
        puts
        next
      end

      # the conversion
      if opt[:translate_to] == :id
        if c1 =~ /.*\:.*/ # it's an id, leave it
          v1 = c1
        else
          v1 = c1obo.term_hash[c1]
        end
        if c2 =~ /.*\:.*/ 
          v2 = c2
        else
          v2 = c2obo.term_hash[c2]
        end
      else
        if c1 =~ /.*\:.*/ 
          v1 = c1obo.id_hash[c1]
        else
          v1 = c1
        end
        if c2 =~ /.*\:.*/ 
          v2 = c2obo.id_hash[c2]
        else
          v2 = c2
        end
      end

      case opt[:output]
      when :cols
        puts "#{v1}\t#{v2}"
      when :xls
        sheet[i,0] = v1
        sheet[i,1] = OboParser::Utilities.term_stanza_from_file(v1, opt[:col1_obo])
        sheet[i,2] = v2
        sheet[i,3] = OboParser::Utilities.term_stanza_from_file(v2, opt[:col2_obo])
      when :homolonto
        s << OboParser::Utilities.homolonto_stanza(i, c1obo.id_hash[v1] , v1, v2) # "#{c1obo.id_hash[v1]} ! #{c2obo.id_hash[v2]}"
        s << "\n\n"
      end
    end

    case opt[:output]
    when :xls
      book.write "#{opt[:output_filename]}.xls"
    when :homolonto 
      puts s + "\n"
    end

    true
  end


  # Takes a two column input file, references it to two ontologies, and returns a report 
  # that identifies data pairs that have parents who are also a data pair given a 
  # provided property/relation type.
  #  
  #== Example use
  #  file = File.read('HAO_TGMA_list.txt')
  #  col1_obo = File.read('hao.obo')
  #  col2_obo = File.read('tgma.obo')
  #
  # foo = OboParser::Utilities.parents(:data => data, :col1_obo => col1_obo, :col2_obo => col2_obo, :property => 'is_a')
  #
  # puts "-- NO (#{foo[:no].size})\n" 
  # puts foo[:no].join("\n")
  # puts "-- YES (#{foo[:yes].size})\n" 
  # puts foo[:yes].join("\n")
  #
  # @param [Hash] options options.
  # @param [Symbol] data the two column data file.
  # @param [Symbol] colo1_obo the OBO file referenced in the first column 
  # @param [Symbol] colo2_obo the OBO file referenced in the second column 
  # @param [Symbol] property the OBO relationship/property to check against (e.g. 'is_a', 'part_of') 
  # @return [Hash] a hash of {:yes => {}, :no => {}}
  def parents(options = {})
    opt = {
      :data => nil,
      :col1_obo => nil,
      :col2_obo => nil,
      :property => nil
    }.merge!(options)

    return false if opt[:property].nil? 
    c1obo = parse_obo_file(opt[:col1_obo])
    c2obo = parse_obo_file(opt[:col2_obo])

    result = {:yes => [], :no => [], :unplaced => []}
    # update
    array = OboParser::Utilities.arrayify_pairs(:data => opt[:data], :col1_obo => opt[:col1_obo], :col2_obo => opt[:col2_obo])

    # index the pairs
    index = array.inject({}){|hsh, i| hsh.update({"#{i[0]}#{i[1]}" => i})}

    obo1_hash = c1obo.id_index
    obo2_hash = c2obo.id_index

    array.each do |k|
      a = k[0]
      b = k[1]

      ids_1 = []
      ids_2 = []

      if !obo1_hash[a]
        puts "can't find #{k}\n"
        next
      end

      if !obo2_hash[b]
        puts "can't find #{k}\n"
        next
      end

      obo1_hash[a].relationships.each do |rel, id| 
        if rel == opt[:property] 
          ids_1.push id
        end
      end

      obo2_hash[b].relationships.each do |rel, id|
        if rel == opt[:property] 
          ids_2.push id
        end
      end

      unplaced = true

      ids_1.each do |c|
        ids_2.each do |d|
          t = "#{a} -> #{b}"
          if index["#{c}#{d}"]   # think this is right   hash[c] == d
            result[:yes].push(t)
            unplaced = false
            next # don't add again after we find a hit
          else
            result[:no].push(t)
            unplaced = false
          end
        end
      end
      result[:unplaced] 

    end

    result
  end


  # Takes a two column input file, references it to two ontologies, and returns a array of [[id1, id2], [id3,idn] ...].
  #
  #== Example use
  #  file = File.read('HAO_TGMA_list.txt')
  #  col1_obo = File.read('hao.obo')
  #  col2_obo = File.read('tgma.obo')
  #  
  #  OboParser::Utilities.arrayify_pairs(:data => file, :col1_obo => col1_obo, :col2_obo => col2_obo)
  #
  # @param [Hash] options options.
  # @param [Symbol] data the two column data file.
  # @param [Symbol] colo1_obo the OBO file referenced in the first column 
  # @param [Symbol] colo2_obo the OBO file referenced in the second column 
  # @return [Array] an array of [[id string, id string], ...]  
  def self.arrayify_pairs(options = {})
    opt = {
      :data => nil,
      :col1_obo => nil,
      :col2_obo => nil,
      :index_start => 0
    }.merge!(options)

    c1obo = parse_obo_file(opt[:col1_obo])
    c2obo = parse_obo_file(opt[:col2_obo])

    array = Array.new

    i = opt[:index_start]
    v1 = nil # a label like 'head'
    v2 = nil
    c1 = nil # an id 'FOO:123'
    c2 = nil

    opt[:data].split(/\n/).each do |row|
      i += 1
      c1, c2 = row.split(/\t/).map(&:strip)

      if c1.nil? || c2.nil?
        next
      end

      # the conversion
      if c1 =~ /.*\:.*/ # it's an id, leave it
        v1 = c1
      else
        v1 = c1obo.term_hash[c1]
      end
      if c2 =~ /.*\:.*/ 
        v2 = c2
      else
        v2 = c2obo.term_hash[c2]
      end

      array << [c1,c2] 

    end
    return array 
  end


  # Provides a set comparisson of correspondances between two sets of correspondances.  Finds correspondances that are shared, in left only, or in right only.
  #  
  #== Example use
  #  data1 = File.read('input/hao_fbbt_vetted_list2.txt')     
  #  data2 = File.read('input/hao_fbbt_from_bioportal.txt')   
  #  col1_obo = File.read('hao.obo')
  #  col2_obo = File.read('tgma.obo')
  #  
  #  OboParser::Utilities.set_comparison(:data1 => data1 , :data2 => data2, :col1_obo => col1_obo, :col2_obo => col2_obo, :return => :text ) # => a text report 
  # or
  #  foo = OboParser::Utilities.set_comparison(:data1 => data1 , :data2 => data2, :col1_obo => col1_obo, :col2_obo => col2_obo, :return => :array ) 
  #
  #== "Report" types 
  # Use :return to return different values 
  #   :array - Returns an Array
  #   :text - Generates 4 column report (id, label, id, label) to STDOUT
  #
  # @param [Hash] options options.
  # @param [Symbol] data1 two columns (tab) with a correspondance between ontologies 1 and 2
  # @param [Symbol] data2 as data1, a second set of correspondances 
  # @param [Symbol] col1_obo the OBO file corresponding to the first column of data1 and data2
  # @param [Symbol] col2_obo the OBO file corresponding to the second column of data1 and data2
  # @param [Symbol] return the value to return
  # @return [String | Array]  
  def self.set_comparison(options = {})
    opt = {
      :data1 => nil,
      :data2 => nil,
      :col1_obo => nil,
      :col2_obo => nil,
      :return => :array # also :text
    }.merge!(options)

    c1obo = parse_obo_file(opt[:col1_obo])
    c2obo = parse_obo_file(opt[:col2_obo])

    th1 = c1obo.id_hash
    th2 = c2obo.id_hash

    array1 =  OboParser::Utilities.arrayify_pairs(:data => opt[:data1], :col1_obo => opt[:col1_obo], :col2_obo => opt[:col2_obo])
    array2 =  OboParser::Utilities.arrayify_pairs(:data => opt[:data2], :col1_obo => opt[:col1_obo], :col2_obo => opt[:col2_obo])

    index1 = array1.inject({}){|hsh, i| hsh.merge!( "#{i[0]}#{i[1]}" => i)}
    index2 = array2.inject({}){|hsh, i| hsh.merge!( "#{i[0]}#{i[1]}" => i)}

    result = {:in_left => [], :in_right => [], :in_both => []}

    result[:in_both]  = (index1.keys & index2.keys).collect{|k| [ index1[k][0], th1[index1[k][0]], index1[k][1], th2[index1[k][1]]                   ,             ]  }
    result[:in_left]  = ((index1.keys | index2.keys)  - index2.keys ).collect{|k| [ index1[k][0], th1[index1[k][0]], index1[k][1], th2[index1[k][1]] ,             ]  }
    result[:in_right] = ((index1.keys | index2.keys)  - index1.keys ).collect{|k| [ index2[k][0], th1[index2[k][0]], index2[k][1], th2[index2[k][1]] ,             ]  }

    case opt[:return]
    when :array
      return result
    when :text
      [:in_both, :in_left, :in_right].each do |t|
        puts "--- #{t.to_s} (#{result[t].size}) ---"
        result[t].each do |r|
          puts r.join("\t")
        end
      end
    else
      return nil
    end
  end


  # Returns a HomolOnto Stanza  
  #
  # @param [String] id an externally tracked id for the id: tag like '00001' 
  # @param [String] name a name for the name: tag
  # @param [Array] members a Array of 2 or more members for the relationship: has_member tag like ['FOO:123', 'BAR:456']
  # @return [String] the stanza requested 
  def self.homolonto_stanza(id, name, *members)
    return 'NOT ENOUGH RELATIONSHIPS' if members.length < 2
    s = []
    s << '[Term]'
    s << "id: HOG:#{id}"
    s << "name: #{name}"
    members.each do |m|
      s << "relationship: has_member #{m}"
    end
    s.join("\n")
  end


  # Takes a Hash of OBO ontology files, an Array of relationships, and writes two input files (a network, and node properties) for Cytoscape
  #  
  #== Example use
  # OboParser::Utilities.cytoscapify(:ontologies => {'HAO' => File.read('input/hao.obo'), 'TADS' => File.read('input/tads.obo'), 'TGMA' => File.read('input/tgma.obo'), 'FBBT' => File.read('input/fbbt.obo') }, :properties => ['is_a', 'part_of'])
  #
  # @param [Symbol] ontologies a Hash of #read files as values, keys as working names
  # @param [Symbol] properties an Array of properties like ['is_a', 'part_of'] 
  # TODO: @return File1, File2, Filen  
  def self.cytoscapify(options = {})
    opt = {
      :ontologies => {},
      :properties => []
    }.merge!(options)

    return false if opt[:properties].empty?
    return false if opt[:ontologies].empty?

    nodes = File.new("nodes.tab", "w+")
    edges = File.new("edges.eda", "w+")

    opt[:ontologies].keys.each do |k|

      obo_file = parse_obo_file(opt[:ontologies][k])

      obo_file.terms.each do |t|
        nodes.puts [t.id.value, t.name.value, k].join("\t") + "\n"

        t.relationships.each do |rel, id|
          edges.puts [t.id.value, "(#{rel})", id].join("\t") + "\n" if opt[:properties].include?(rel)
        end
      end
    end

    nodes.close
    edges.close

    true

  end


  #== Helper methods that don't require the obo_parser library

  # Given a Term id and a String representing an OBO file returns that stanza. 
  #
  # @param [String] id a Term id like 'FOO:123' 
  # @param [String] file a Obo file as a String like File.read('my.obo') 
  # @return [String] the stanza requested 
  def self.term_stanza_from_file(id, file)
    foo = ""
    file =~ /(^\[Term\]\s*?id:\s*?#{id}.*?)(^\[Term\]|^\[Typedef\])/im
    foo = $1 if !$1.nil?
    foo.gsub(/\n\r/,"\n")
  end

end
