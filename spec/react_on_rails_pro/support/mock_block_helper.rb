# frozen_string_literal: true

module MockBlockHelper
  # This is a class that can be used to mock a block.
  # It can be used to test that a block is called with the correct arguments.
  #
  # Usage:
  #
  # mocked_block = mock_block
  # testing_method_taking_block(&mocked_block.block)
  # expect(mocked_block).to have_received(:call).with(1, 2, 3)
  def mock_block(return_value: nil)
    double("BlockMock").tap do |mock| # rubocop:disable RSpec/VerifiedDoubles
      allow(mock).to receive(:call) { return_value }
      def mock.block
        method(:call).to_proc
      end
    end
  end
end

RSpec.configure do |config|
  config.include MockBlockHelper
end
