require 'yaml'

module Byebug
  module Printers
    #
    # Base printer
    #
    class Base
      class MissedPath < StandardError; end
      class MissedArgument < StandardError; end

      SEPARATOR = '.'

      def type
        self.class.name.split('::').last.downcase
      end

      private

      def locate(path)
        result = nil
        contents.each do |_, contents|
          result = parts(path).reduce(contents) do |r, part|
            r && r.key?(part) ? r[part] : nil
          end
          break if result
        end
        fail MissedPath, "Can't find part path '#{path}'" unless result
        result
      end

      def translate(string, args = {})
        # they may contain #{} string interpolation
        string.gsub(/\|\w+$/, '').gsub(/([^#]?){([^}]*)}/) do
          key = Regexp.last_match[2].to_s
          unless args.key?(key.to_sym)
            fail MissedArgument, "Missed argument #{key} for '#{string}'"
          end

          "#{Regexp.last_match[1]}#{args[key.to_sym]}"
        end
      end

      def parts(path)
        path.split(SEPARATOR)
      end

      def contents
        @contents ||= contents_files.each_with_object({}) do |filename, hash|
          hash[filename] = YAML.load_file(filename) || {}
        end
      end

      def array_of_args(collection, &block)
        collection_with_index = collection.each.with_index
        collection_with_index.each_with_object([]) do |(item, index), array|
          args = block.call(item, index)
          array << args if args
        end
      end

      def contents_files
        [File.expand_path(File.join('..', 'texts', 'base.yml'), __FILE__)]
      end
    end
  end
end
