require "set"
require "pathname"
require "mutex_m"

module Spring
  module Watcher
    # A user of a watcher can use IO.select to wait for changes:
    #
    #   watcher = MyWatcher.new(root, latency)
    #   IO.select([watcher]) # watcher is running in background
    #   watcher.stale? # => true
    class Abstract
      include Mutex_m

      attr_reader :files, :directories, :root, :latency

      def initialize(root, latency)
        super()

        @root        = File.realpath(root)
        @latency     = latency
        @files       = Set.new
        @directories = Set.new
        @stale       = false
        @listeners   = []
      end

      def add(*items)
        items = items.flatten.map do |item|
          item = Pathname.new(item)

          if item.relative?
            Pathname.new("#{root}/#{item}")
          else
            item
          end
        end

        items = items.select(&:exist?)

        synchronize {
          items.each do |item|
            if item.directory?
              directories << item.realpath.to_s
            else
              files << item.realpath.to_s
            end
          end

          subjects_changed
        }
      end

      def stale?
        @stale
      end

      def on_stale(&block)
        @listeners << block
      end

      def mark_stale
        return if stale?
        @stale = true
        @listeners.each(&:call)
      end

      def restart
        stop
        start
      end

      def start
        raise NotImplementedError
      end

      def stop
        raise NotImplementedError
      end

      def subjects_changed
        raise NotImplementedError
      end
    end
  end
end
