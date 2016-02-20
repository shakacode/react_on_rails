module WebConsole
  class View < ActionView::Base
    # Execute a block only on error pages.
    #
    # The error pages are special, because they are the only pages that
    # currently require multiple bindings. We get those from exceptions.
    def only_on_error_page(*args)
      yield if @env['web_console.exception'].present?
    end

    # Render JavaScript inside a script tag and a closure.
    #
    # This one lets write JavaScript that will automatically get wrapped in a
    # script tag and enclosed in a closure, so you don't have to worry for
    # leaking globals, unless you explicitly want to.
    def render_javascript(template)
      render(template: template, layout: 'layouts/javascript')
    end

    # Render inlined string to be used inside of JavaScript code.
    #
    # The inlined string is returned as an actual JavaScript string. You
    # don't need to wrap the result yourself.
    def render_inlined_string(template)
      render(template: template, layout: 'layouts/inlined_string')
    end

    # Override method for ActionView::Helpers::TranslationHelper#t.
    #
    # This method escapes the original return value for JavaScript, since the
    # method returns a HTML tag with some attributes when the key is not found,
    # so it could cause a syntax error if we use the value in the string literals.
    def t(key, options = {})
      j super
    end
  end
end
