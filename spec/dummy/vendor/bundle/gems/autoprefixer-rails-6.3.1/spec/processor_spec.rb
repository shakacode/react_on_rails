require_relative 'spec_helper'

describe AutoprefixerRails::Processor do

  it 'parses config' do
    config    = "# Comment\n ie 11\n \nie 8 # sorry\n"
    processor = AutoprefixerRails::Processor.new
    expect(processor.parse_config(config)).to eql(['ie 11', 'ie 8'])
  end

end
