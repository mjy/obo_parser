require 'rubygems'
require 'ruby-debug'
require File.expand_path(File.join(File.dirname(__FILE__), 'obo_parser')) 

module OboParser::Utilities

  # Example usage
	#	of1 = File.read('hao1.obo')	
	#	of2 = File.read('hao2.obo')	
	#	of3 = File.read('hao3.obo')	
	#	of4 = File.read('hao4.obo')	
  #
  # OboParser::Utilities::dump_comparison_by_id([of1, of2, of3, of4])
  def self.dump_comparison_by_id(files = []) # :yields: String
    of = [] 
    files.each_with_index do |f, i|
      of[i] = parse_obo_file(f)	
    end
    
    all_data = {}

    of.each do |f|
      tmp_hash = f.id_hash
      tmp_hash.keys.each do |id|
        if all_data[id]
          all_data[id].push tmp_hash[id]
        else
          all_data[id] = [tmp_hash[id]]
        end
      end
    end

    puts "\nA list of all labels used across all submitted files for a given ID\n\n"
    all_data.keys.sort.each do |k|
      if all_data[k].uniq.size > 1
        puts "#{k}\t: #{all_data[k].uniq.join(', ')}"
      end
    end
  end

  # infile is a tab delimited 2 column file that contains IDs in the from FOO_1234
  # The file is replicated to STDOUT replacing the ID with the Term
  def self.alignment_translate(infile = nil) # :yields: String
    agreement = ARGV[0]
    raise "Provide a file with comparison." if agreement.nil? 
    comparison = File.read(agreement)
   
    obo_files = Dir.entries('.').inject([]){|sum, a| sum.push( a =~ /\.obo\Z/ ? a : nil)}.compact!
    identifiers = {}

    obo_files.each do |f|
      puts "Reading: #{f}"
      identifiers.merge!(  parse_obo_file(File.read(f)).id_hash )
    end
    
    comparison.each do |l|
      v1, v2 = l.split("\t")
      # puts "#{v1} - #{v2}"

      next if v1.nil? || v2.nil?

      v1.gsub!(/_/, ":")
      v1.strip!
      v2.gsub!(/_/, ":")
      v2.strip!

      puts (identifiers[v1].nil? ? 'NOT FOUND' : identifiers[v1]) +
            "\t" +
           (identifiers[v2].nil? ? 'NOT FOUND' : identifiers[v2]) 
    end
  end 

  # Returns labels found in all passed ontologies 
  # Usage:
  #  of1 = File.read('fly_anatomy.obo')	
  #  of2 = File.read('hao.obo')	
  #  of3 = File.read('mosquito_anatomy.obo')	
  #  shared_labels([of1, of6])
  def self.shared_labels(files = []) # :yields: String
    comparison = {}

    files.each do |f|
      o = parse_obo_file(f)
      o.term_hash.keys.each do |k|
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

   puts  match.sort.join("\n")
   puts "\n#{match.length} total."

  end 
 
end
