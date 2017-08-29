require 'spec_helper'

describe OboParser::Utilities::Viz do
  let(:o) { File.read(File.expand_path(File.join(File.dirname(__FILE__), '../../files/hao.obo')) ) }

  specify '#mock_coordinate_space' do
    expect(OboParser::Utilities::Viz.mock_coordinate_space(o, size: 50, cuttoff: 10)).to be_truthy
  end
end
