# frozen_string_literal: true

module ReactOnRailsPro
  module Stream
    # Streams React components within a specified template to the client.
    #
    # @param template [String] The path to the template file to be streamed.
    # @param close_stream_at_end [Boolean] Whether to automatically close the stream after rendering (default: true).
    #
    # components must be added to the view using the `stream_react_component` helper.
    #
    # @example
    #   stream_view_containing_react_components(template: 'path/to/your/template')
    #
    # @note The `stream_react_component` helper is defined in the react_on_rails gem.
    #       For more details, refer to `lib/react_on_rails/helper.rb` in the react_on_rails repository.
    #
    # @see ReactOnRails::Helper#stream_react_component
    def stream_view_containing_react_components(template:, close_stream_at_end: true)
      @rorp_rendering_fibers = []
      template_string = render_to_string(template: template)
      response.stream.write(template_string)

      @rorp_rendering_fibers.each do |fiber|
        while (chunk = fiber.resume)
          response.stream.write(chunk)
        end
      end
      response.stream.close if close_stream_at_end
    end
  end
end
