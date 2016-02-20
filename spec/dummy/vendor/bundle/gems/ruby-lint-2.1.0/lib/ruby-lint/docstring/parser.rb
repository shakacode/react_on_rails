module RubyLint
  module Docstring
    ##
    # {RubyLint::Docstring::Parser} parses a collection of Ruby source comments
    # and tries to extract various YARD tags out of them. These tags can then
    # be used as extra information for building definitions (e.g. the arguments
    # of a method definition).
    #
    class Parser
      ##
      # Regexp used to get rid of leading `#` markers. This makes the regular
      # expressions used for tags a little bit easier.
      #
      # @return [Regexp]
      #
      COMMENT_REGEXP = /^#+\s*/

      ##
      # The character used for separating types in a tag.
      #
      # @return [String]
      #
      TYPE_SEPARATOR = '|'

      ##
      # Hash containing regular expressions and their corresponding callback
      # methods.
      #
      # @return [Hash]
      #
      KNOWN_TAGS = {
        # Matches: @param [Type] name description
        # Matches: @param [Type<Value>] name description
        /^@param\s+\[(.+)\]\s+(\S+)\s*(.+)*/ => :on_param_with_type,

        # Matches: @param name description
        /^@param\s+(\S+)\s*(.+)*/ => :on_param,

        # Matches: @return [Type] description
        /^@return\s+\[(.+)\]\s*(.+)*/ => :on_return_with_type,

        # Matches; @return description
        /^@return\s+(.+)/ => :on_return,
      }

      ##
      # Parses an Array of comments and returns a collection of docstring tags.
      #
      # @param [Array] comments
      # @return [Array]
      #
      def parse(comments)
        tags = []

        comments.each do |comment|
          comment = comment.gsub(COMMENT_REGEXP, '').strip

          KNOWN_TAGS.each do |regexp, method|
            matchdata = comment.match(regexp)

            if matchdata
              retval = send(method, *matchdata.captures)

              if retval
                tags << retval
                break
              end
            end
          end
        end

        return tags
      end

      private

      ##
      # Processes a `@param` tag without a given type.
      #
      # @param [String] name The name of the argument.
      # @param [String] description The description of the argument.
      # @return [RubyLint::Docstring::ParamTag]
      #
      def on_param(name, description)
        return ParamTag.new(:name => name, :description => description)
      end

      ##
      # Processes a `@param` tag with a set of types specified.
      #
      # @param [String] types The argument types.
      # @see #on_param
      #
      def on_param_with_type(types, name, description)
        # The inner values of compound types are ignored since ruby-lint
        # doesn't have the means to store this information.
        types = types.split(TYPE_SEPARATOR).map do |type|
          type.gsub(/<.+>/, '')
        end

        return ParamTag.new(
          :name        => name,
          :description => description,
          :types       => types
        )
      end

      ##
      # Processes a `@return` tag with just the description.
      #
      # @param [String] description
      # @return [RubyLint::Docstring::ReturnTag]
      #
      def on_return(description)
        return ReturnTag.new(:description => description)
      end

      ##
      # Processes a `@return` tag with the type and description.
      #
      # @param [String] types The return types.
      # @param [String] description
      # @return [RubyLint::Docstring::ReturnTag]
      #
      def on_return_with_type(types, description)
        return ReturnTag.new(
          :description => description,
          :types       => types.split(TYPE_SEPARATOR)
        )
      end
    end # DocstringParser
  end # Docstring
end # RubyLint
