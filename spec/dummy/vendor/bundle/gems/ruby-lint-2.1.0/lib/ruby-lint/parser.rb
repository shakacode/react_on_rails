module RubyLint
  ##
  # {RubyLint::Parser} provides a small wrapper around the Parser Gem and
  # allows for the use of a custom AST builder.
  #
  # @!attribute [r] internal_parser
  #  @return [Parser::Parser]
  #
  class Parser
    attr_reader :internal_parser

    def initialize
      builder          = AST::Builder.new
      @internal_parser = ::Parser::CurrentRuby.new(builder)

      internal_parser.diagnostics.all_errors_are_fatal = false
    end

    ##
    # Registers the consumer with the internal diagnostics handler.
    #
    # @param [#call] consumer
    #
    def consumer=(consumer)
      internal_parser.diagnostics.consumer = consumer
    end

    ##
    # Parses a block of Ruby code and returns the AST and a mapping of each AST
    # node and their comments (if there are any). This mapping is returned as a
    # Hash.
    #
    # @param [String] code
    # @param [String] file
    # @param [Numeric] line
    # @return [Array]
    #
    def parse(code, file = '(ruby-lint)', line = 1)
      buffer        = ::Parser::Source::Buffer.new(file, line)
      buffer.source = code
      ast, comments = internal_parser.parse_with_comments(buffer)

      internal_parser.reset

      associated = associate_comments(ast, comments)

      return create_root_node(ast), associated
    end

    private

    ##
    # @param [RubyLint::AST::Node|NilClass] ast
    # @return [RubyLint::AST::Node]
    #
    def create_root_node(ast)
      if ast
        children = [ast]
        location = ast.location
      # empty input.
      else
        children = []
        location = nil
      end

      return AST::Node.new(:root, children, :location => location)
    end

    ##
    # @param [RubyLint::AST::Node|NilClass] ast
    # @param [Mixed] comments
    # @return [Hash]
    #
    def associate_comments(ast, comments)
      if ast
        associator = ::Parser::Source::Comment::Associator.new(ast, comments)
        associated = associator.associate
      else
        associated = {}
      end

      return associated
    end
  end # Parser
end # RubyLint
