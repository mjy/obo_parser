require 'spec_helper'

describe OboParser::Utilities::Viz do
  let(:o) { parse_obo_file( 
                           File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../files/hao.obo')) )
                          ) }

  specify '#mock_coordinate_space' do
    capture_stderr do 
      expect(OboParser::Utilities::Viz.mock_coordinate_space(o, size: 50, cutoff: 10)).to be_truthy
    end
  end
end
