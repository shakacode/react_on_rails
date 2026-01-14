# frozen_string_literal: true

require "async"
require "async/barrier"

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
      @rescue_blocks = []
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

    def rescue(&block)
      @rescue_blocks << block
      self # Return self to allow chaining
    end

    def handle_chunk(chunk, position)
      @actions.reduce(chunk) do |acc, action|
        action.call(acc, position)
      end
    end

    def each_chunk(&block) # rubocop:disable Metrics/CyclomaticComplexity
      return enum_for(:each_chunk) unless block

      first_chunk = true
      @component.each_chunk do |chunk|
        position = first_chunk ? :first : :middle
        modified_chunk = handle_chunk(chunk, position)
        yield(modified_chunk)
        first_chunk = false
      end

      # The last chunk contains the append content after the transformation
      # All transformations are applied to the append content
      last_chunk = handle_chunk("", :last)
      yield(last_chunk) unless last_chunk.empty?
    rescue StandardError => e
      current_error = e
      rescue_block_index = 0
      while current_error.present? && (rescue_block_index < @rescue_blocks.size)
        begin
          @rescue_blocks[rescue_block_index].call(current_error, &block)
          current_error = nil
        rescue StandardError => inner_error
          current_error = inner_error
        end
        rescue_block_index += 1
      end
      raise current_error if current_error.present?
    end
  end

  class StreamRequest
    def initialize(&request_block)
      @request_executor = request_block
    end

    private_class_method :new

    def each_chunk(&block)
      return enum_for(:each_chunk) unless block

      Sync do
        barrier = Async::Barrier.new

        send_bundle = false
        error_body = +""
        loop do
          stream_response = @request_executor.call(send_bundle, barrier)

          # Chunks can be merged during streaming, so we separate them by newlines
          # Also, we check the status code inside the loop block because calling `status` outside the loop block
          # is blocking, it will wait for the response to be fully received
          # Look at the spec of `status` in `spec/react_on_rails_pro/stream_spec.rb` for more details
          process_response_chunks(stream_response, error_body, &block)
          break
        rescue HTTPX::HTTPError => e
          send_bundle = handle_http_error(e, error_body, send_bundle)
        rescue HTTPX::ReadTimeoutError => e
          raise ReactOnRailsPro::Error, "Time out error while server side render streaming a component.\n" \
                                        "Original error:\n#{e}\n#{e.backtrace}"
        end

        barrier.wait
      end
    end

    def process_response_chunks(stream_response, error_body)
      loop_response_lines(stream_response) do |chunk|
        if stream_response.is_a?(HTTPX::ErrorResponse) || stream_response.status >= 400
          error_body << chunk
          next
        end

        processed_chunk = chunk.strip
        puts "SSR Chunk (Ruby Side): #{processed_chunk}"
        yield processed_chunk unless processed_chunk.empty?
      end
    end

    def handle_http_error(error, error_body, send_bundle)
      response = error.response
      case response.status
      when ReactOnRailsPro::STATUS_SEND_BUNDLE
        # To prevent infinite loop
        ReactOnRailsPro::Error.raise_duplicate_bundle_upload_error if send_bundle

        true
      when ReactOnRailsPro::STATUS_INCOMPATIBLE
        raise ReactOnRailsPro::Error, error_body
      else
        raise ReactOnRailsPro::Error, "Unexpected response code from renderer: #{response.status}:\n#{error_body}"
      end
    end

    # Method to start the decoration
    def self.create(&request_block)
      StreamDecorator.new(new(&request_block))
    end

    private

    # This method is considered as an override of response.each_line
    # It fixes the problem of not yielding the last chunk on error
    # You can check the spec of `each_line` in `spec/react_on_rails_pro/stream_spec.rb` for more details
    def loop_response_lines(response)
      return enum_for(__method__, response) unless block_given?

      line = "".b

      puts "[Ruby Side] Starting to iterate response..."
      response.each do |chunk|
        puts "[Ruby Side] Got response chunk: #{chunk.strip[0..200]}..."
        response.instance_variable_set(:@react_on_rails_received_first_chunk, true)
        line << chunk

        while (idx = line.index("\n"))
          yield line.byteslice(0..idx - 1)

          line = line.byteslice(idx + 1..-1)
        end
      end
      puts "[Ruby Side] Finished iterating response."
    ensure
      yield line unless line.empty?
    end
  end
end
