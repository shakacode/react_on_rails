module RubyLint
  module Docstring
    ##
    # {RubyLint::Docstring::Mapping} is a small data container for storing
    # docstring tags separately and optionally by their names (e.g. for
    # parameter tags).
    #
    # @!attribute [r] param_tags
    #  @return [Hash]
    #
    # @!attribute [r] return_tag
    #  @return [RubyLint::Docstring::ReturnTag]
    #
    class Mapping
      attr_reader :param_tags, :return_tag

      ##
      # Hash containing the known tag classes and their callback methods.
      #
      # @return [Hash]
      #
      TAG_METHODS = {
        ParamTag  => :on_param_tag,
        ReturnTag => :on_return_tag
      }

      ##
      # @param [Array] tags
      #
      def initialize(tags = [])
        @param_tags = {}

        tags.each do |tag|
          send(TAG_METHODS[tag.class], tag)
        end
      end

      private

      ##
      # @param [RubyLint::Docstring::ParamTag] tag
      #
      def on_param_tag(tag)
        @param_tags[tag.name] = tag
      end

      ##
      # @param [RubyLint::Docstring::ReturnTag] tag
      #
      def on_return_tag(tag)
        @return_tag = tag
      end
    end # Mapping
  end # Docstring
end # RubyLint
