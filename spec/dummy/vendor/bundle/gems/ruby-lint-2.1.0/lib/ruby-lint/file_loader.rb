module RubyLint
  ##
  # {RubyLint::FileLoader} iterates over an AST and given a constant node will
  # try to find the corresponding filepath using {RubyLint::FileScanner}.
  #
  # ## Options
  #
  # The following options must be set when creating an instance of this class:
  #
  # * `:directories`: the directories to scan for files.
  # * `:ignore_paths`: a list of paths to ignore when scanning for files.
  #
  # @!attribute [r] file_scanner
  #  @return [RubyLint::FileScanner]
  #
  # @!attribute [r] parser
  #  @return [RubyLint::Parser]
  #
  # @!attribute [r] nodes
  #  @return [Array] A list of extra nodes (and their comments) a VM instance
  #   should process before processing the file being analyzed.
  #
  # @!attribute [r] paths
  #  @return [Set]
  #
  class FileLoader < Iterator
    attr_reader :file_scanner, :parser, :nodes, :comments, :paths

    ##
    # Called after a new instance of this class is created.
    #
    def after_initialize
      @file_scanner = FileScanner.new(@directories, @ignore_paths)
      @parser       = Parser.new
      @nodes        = []
      @paths        = Set.new
    end

    ##
    # @param [RubyLint::AST::Node] node
    #
    def on_const(node)
      const_path = ConstantPath.new(node)

      files      = file_scanner.scan(const_path.to_s)
      last_name  = const_path.constant_segments.last.last

      paths << node.file

      files.each do |path|
        next if paths.include?(path)

        paths << path

        process_file(last_name, path)
      end
    end

    private

    ##
    # @param [String] constant_name
    # @param [String] path
    #
    def process_file(constant_name, path)
      code = File.read(path)

      return unless code.include?(constant_name)

      ast, comments = parser.parse(code, path)

      iterate(ast)

      nodes << [ast, comments]
    end
  end # FileLoader
end # RubyLint
