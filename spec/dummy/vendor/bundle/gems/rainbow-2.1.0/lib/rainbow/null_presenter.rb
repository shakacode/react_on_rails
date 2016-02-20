module Rainbow

  class NullPresenter < ::String

    def color(*values); self; end
    def background(*values); self; end
    def reset; self; end
    def bright; self; end
    def italic; self; end
    def underline; self; end
    def blink; self; end
    def inverse; self; end
    def hide; self; end

    def black; self; end
    def red; self; end
    def green; self; end
    def yellow; self; end
    def blue; self; end
    def magenta; self; end
    def cyan; self; end
    def white; self; end

    alias_method :foreground, :color
    alias_method :fg, :color
    alias_method :bg, :background

  end

end
