module Spring
  module Test
    class RailsVersion
      attr_reader :version

      def initialize(string)
        @version = Gem::Version.new(string)
      end

      def rails_3?
        version < Gem::Version.new("4.0.0")
      end
      alias needs_testunit? rails_3?

      def test_command
        needs_testunit? ? 'bin/testunit' : 'bin/rake test'
      end

      def controller_tests_dir
        rails_3? ? 'functional' : 'controllers'
      end

      def bundles_spring?
        version.segments.take(2) == [4, 1] || version > Gem::Version.new("4.1")
      end

      def major
        version.segments[0]
      end

      def minor
        version.segments[1]
      end

      def to_s
        version.to_s
      end
    end
  end
end
