# frozen_string_literal: true

module ReactOnRailsPro
  class StreamDecorator
    def initialize(component)
      @component = component
      # @type [Array[Proc]]
      # Proc receives 2 arguments: chunk, position
      # @param chunk [String] The chunk to be processed
      # @param position [Symbol] The position of the chunk in the stream (:first, :middle, or :last)
      # The position parameter is used by actions that add content to the beginning or end of the stream
      @actions = [] # List to store all actions
    end

    # Add a prepend action
    def prepend
      @actions << ->(chunk, position) { position == :first ? "#{yield}#{chunk}" : chunk }
      self # Return self to allow chaining
    end

    # Add a transformation action
    def transform
      @actions << lambda { |chunk, position|
        if position == :last && chunk.empty?
          # Return the empty chunk without modification for the last chunk
          # This is related to the `handleChunk(:last, "")` call which gets all the appended content
          # We don't want to make an extra call to the transformer block if there is no content appended
          chunk
        else
          yield(chunk)
        end
      }
      self # Return self to allow chaining
    end

    # Add an append action
    def append
      @actions << ->(chunk, position) { position == :last ? "#{chunk}#{yield}" : chunk }
      self # Return self to allow chaining
    end

    def handle_chunk(chunk, position)
      @actions.reduce(chunk) do |acc, action|
        action.call(acc, position)
      end
    end

    def each_chunk
      return enum_for(:each_chunk) unless block_given?

      first_chunk = true
      @component.each_chunk do |chunk|
        position = first_chunk ? :first : :middle
        modified_chunk = handle_chunk(chunk, position)
        yield modified_chunk
        first_chunk = false
      end

      # The last chunk contains the append content after the transformation
      # All transformations are applied to the append content
      last_chunk = handle_chunk("", :last)
      yield last_chunk unless last_chunk.empty?
    end
  end

  class StreamRequest
    def initialize(&request_block)
      @request_executor = request_block
    end

    private_class_method :new

    def each_chunk
      return enum_for(:each_chunk) unless block_given?

      send_bundle = false
      loop do
        stream_response = @request_executor.call(send_bundle)
        # stream_response.each may yield merged chunks, but the real chunks are separated by newlines.
        stream_response.each_line do |chunk|
          stripped_chunk = chunk.strip
          yield stripped_chunk unless stripped_chunk.empty?
        end
        break
      rescue HTTPX::HTTPError => e
        response = e.response
        case response.status
        when ReactOnRailsPro::STATUS_SEND_BUNDLE
          send_bundle = true
          next
        when ReactOnRailsPro::STATUS_INCOMPATIBLE
          raise ReactOnRailsPro::Error, response.body
        else
          raise ReactOnRailsPro::Error, "Unexpected response code from renderer: #{response.status}:\n#{response.body}"
        end
      end
    end

    # Method to start the decoration
    def self.create(&request_block)
      StreamDecorator.new(new(&request_block))
    end
  end
end
