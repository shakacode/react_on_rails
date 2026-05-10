# frozen_string_literal: true

module MockBlockHelper
  class BlockMock
    def initialize(callback)
      @callback = callback
    end

    def call(*args, &inner_block)
      @callback&.call(*args, &inner_block)
    end

    def block
      method(:call).to_proc
    end
  end

  # This is a class that can be used to mock a block.
  # It can be used to test that a block is called with the correct arguments.
  #
  # Usage:
  #
  # mocked_block = mock_block
  # testing_method_taking_block(&mocked_block.block)
  # expect(mocked_block).to have_received(:call).with(1, 2, 3)
  def mock_block(&block)
    BlockMock.new(block).tap do |mock|
      allow(mock).to receive(:call).and_call_original
    end
  end
end

RSpec.configure do |config|
  config.include MockBlockHelper
end
