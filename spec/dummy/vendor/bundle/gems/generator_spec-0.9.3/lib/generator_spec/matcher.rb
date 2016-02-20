module GeneratorSpec
  module Matcher
    # Taken (with permission) from beard by Yahuda Katz
    # https://github.com/carlhuda/beard
  
    class File
      def initialize(name, &block)
        @contents = []
        @name = name

        if block_given?
          instance_eval(&block)
        end
      end

      def contains(text)
        @contents << text
      end

      def matches?(root)
        unless root.join(@name).exist?
          throw :failure, root.join(@name)
        end

        check_contents(root.join(@name))
      end
      
      protected
      
      def check_contents(file)
        contents = ::File.read(file)

        @contents.each do |string|
          unless contents.include?(string)
            throw :failure, [file, string, contents]
          end
        end
      end
    end
    
    class Migration < File
      def matches?(root)
        file_name = migration_file_name(root, @name)
        
        unless file_name && file_name.exist?
          throw :failure, @name
        end
        
        check_contents(file_name)
      end
      
      protected
      
      def migration_file_name(root, name) #:nodoc:
        directory, file_name = ::File.dirname(root.join(name)), ::File.basename(name).sub(/\.rb$/, '')
        migration = Dir.glob("#{directory}/[0-9]*_*.rb").grep(/\d+_#{file_name}.rb$/).first
        Pathname.new(migration) if migration
      end
    end

    class Directory
      attr_reader :tree

      def initialize(root = nil, &block)
        @tree = {}
        @negative_tree = []
        @root = root
        instance_eval(&block) if block_given?
      end

      def directory(name, &block)
        @tree[name] = block_given? && Directory.new(location(name), &block)
      end

      def file(name, &block)
        @tree[name] = File.new(location(name), &block)
      end

      def no_file(name)
        @negative_tree << name
      end

      def location(name)
        [@root, name].compact.join("/")
      end
      
      def migration(name, &block)
        @tree[name] = Migration.new(location(name), &block)
      end

      def matches?(root)
        @tree.each do |file, value|
          unless value
            unless root.join(location(file)).exist?
              throw :failure, "#{root}/#{location(file)}"
            end
          else
            value.matches?(root)
          end
        end

        @negative_tree.each do |file|
          if root.join(location(file)).exist?
            throw :failure, [:not, "unexpected #{root}/#{location(file)}"]
          end
        end

        nil
      end
    end

    class Root < Directory
      def failure_message
        if @failure.is_a?(Array) && @failure[0] == :not
          "Structure should not have had #{@failure[1]}, but it did"
        elsif @failure.is_a?(Array)
          "Structure should have #{@failure[0]} with #{@failure[1]}. It had:\n#{@failure[2]}"
        else
          "Structure should have #{@failure}, but it didn't"
        end
      end

      def matches?(root)
        root = Pathname.new(root) unless root.is_a?(Pathname)
        @failure = catch :failure do
          super
        end

        !@failure
      end
    end

    def have_structure(&block)
      Root.new(&block)
    end
  end
end