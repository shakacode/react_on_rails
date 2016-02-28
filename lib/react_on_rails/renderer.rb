module ReactOnRails
  class Renderer
    def initialize(react_component_name, props, options, request); end
    def self.before_render; ""; end
    def self.after_render; ""; end
  end
end
