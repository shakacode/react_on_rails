# frozen_string_literal: true

module ReactOnRailsPro
  class StreamCache
    class << self
      # Returns a stream-like object that responds to `each_chunk` and yields cached chunks
      # or nil if not present in cache.
      def fetch_stream(cache_key)
        cached_chunks = Rails.cache.read(cache_key)
        return nil unless cached_chunks.is_a?(Array)

        build_stream_from_chunks(cached_chunks)
      end

      # Wraps an upstream stream (responds to `each_chunk`), yields chunks downstream while
      # buffering them, and writes the chunks array to Rails.cache on successful completion.
      # Returns a stream-like object that responds to `each_chunk`.
      def wrap_and_cache(cache_key, upstream_stream, cache_options: nil)
        component = CachingComponent.new(upstream_stream, cache_key, cache_options)
        ReactOnRailsPro::StreamDecorator.new(component)
      end

      # Builds a stream-like object from an array of chunks.
      def build_stream_from_chunks(chunks)
        component = CachedChunksComponent.new(chunks)
        ReactOnRailsPro::StreamDecorator.new(component)
      end
    end

    class CachedChunksComponent
      def initialize(chunks)
        @chunks = chunks
      end

      def each_chunk(&block)
        return enum_for(:each_chunk) unless block

        @chunks.each(&block)
      end
    end

    class CachingComponent
      def initialize(upstream_stream, cache_key, cache_options)
        @upstream_stream = upstream_stream
        @cache_key = cache_key
        @cache_options = cache_options
      end

      def each_chunk(&block)
        return enum_for(:each_chunk) unless block

        buffered_chunks = []
        @upstream_stream.each_chunk do |chunk|
          buffered_chunks << chunk
          yield(chunk)
        end
        Rails.cache.write(@cache_key, buffered_chunks, @cache_options || {})
      end
    end
  end
end
