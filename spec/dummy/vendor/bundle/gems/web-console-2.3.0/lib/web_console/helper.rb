module WebConsole
  module Helper
    # Communicates with the middleware to render a console in a +binding+.
    #
    # If +bidning+ isn't explicitly given, Binding#of_caller will be used to
    # get the binding of the previous frame. E.g. the one that invoked
    # +console+.
    #
    # Raises DoubleRenderError if a double +console+ invocation per request is
    # detected.
    def console(binding = nil)
      raise DoubleRenderError if request.env['web_console.binding']

      request.env['web_console.binding'] = binding || ::Kernel.binding.of_caller(1)

      # Make sure nothing is rendered from the view helper. Otherwise
      # you're gonna see unexpected #<Binding:0x007fee4302b078> in the
      # templates.
      nil
    end
  end
end
