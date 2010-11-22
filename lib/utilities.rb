require 'rubygems'
require 'ruby-debug'
require 'obo_parser'

module OboParser::Utilities


  # Example usages
	#	of1 = File.read('hao1.obo')	
	#	of2 = File.read('hao2.obo')	
	#	of3 = File.read('hao3.obo')	
	#	of4 = File.read('hao4.obo')	
  #
  #  OboParser::Utilities::dump_comparison_by_id([of1, of2, of3, of4])

  def self.dump_comparison_by_id(files = [])
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
 
end
