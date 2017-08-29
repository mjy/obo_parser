module OboParser
  module Utilities

    # Methods to aid in visualization
    module Helpers 

      # @return [Array]
      #   rows of data from ontology, just ID, name
      def self.simple_data(ontology)
        data = []

        ontology.terms.each do |t|
          row = []
          row.push(t.id.value)
          row.push(t.name.value)
          data.push row
        end
        data 
      end

    end
  end
end
