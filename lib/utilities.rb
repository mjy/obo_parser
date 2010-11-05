require 'rubygems'
require 'ruby-debug'
require 'obo_parser'

module OboParser::Utilities

  def dump_comparison_by_id(files = [])
    of = [] 
    files.each_with_index do |f, i|
      of[i] = parse_obo_file(File.read(f))	
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

    all_data.keys.sort.each do |k|
      if all_data[k].uniq.size > 1
        puts "#{k}\t: #{all_data[k].uniq.join(', ')}"
      end
    end

  end
 
end
