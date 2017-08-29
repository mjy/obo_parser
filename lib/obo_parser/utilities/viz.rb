module OboParser
  module Utilities

    # Methods to aid in visualization
    module Viz

      # @params [ontology]
      #   the result of a parse_obo_file
      def self.mock_coordinate_space(ontology, size: 20)

        data = OboParser::Utilities::Helpers.simple_data(ontology)

        x,y,z = 1,1,1
        center_distance = ( size / 2) 
        edge_length = (size / 2) - (size * 0.2)
        total_terms = ontology.terms.size

        grid_length = Math.cbrt(total_terms).ceil.to_i

        puts "size: #{size}"
        # puts "edge_length: #{edge_length}"
        puts "grid_length: #{grid_length}"

        data.each do |row|
          print x * center_distance
          print "\t"
          print y * center_distance
          print "\t"
          print z * center_distance
          print "\t"
          print row[0]
          print "\t"
          print row[1]
          print "\n"

          x = x + 1
          if (x % grid_length) == 0
            x = 1
            y = y + 1
          end

          if (y % grid_length) == 0
            y = 1
            x = 1
            z = z + 1
          end
        end
      end
    end
  end
end
