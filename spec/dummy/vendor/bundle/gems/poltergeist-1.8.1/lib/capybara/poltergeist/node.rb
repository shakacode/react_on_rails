module Capybara::Poltergeist
  class Node < Capybara::Driver::Node
    attr_reader :page_id, :id

    def initialize(driver, page_id, id)
      super(driver, self)

      @page_id = page_id
      @id      = id
    end

    def browser
      driver.browser
    end

    def command(name, *args)
      browser.send(name, page_id, id, *args)
    rescue BrowserError => error
      case error.name
      when 'Poltergeist.ObsoleteNode'
        raise ObsoleteNode.new(self, error.response)
      when 'Poltergeist.MouseEventFailed'
        raise MouseEventFailed.new(self, error.response)
      else
        raise
      end
    end

    def parents
      command(:parents).map { |parent_id| self.class.new(driver, page_id, parent_id) }
    end

    def find(method, selector)
      command(:find_within, method, selector).map { |id| self.class.new(driver, page_id, id) }
    end

    def find_xpath(selector)
      find :xpath, selector
    end

    def find_css(selector)
      find :css, selector
    end

    def all_text
      filter_text command(:all_text)
    end

    def visible_text
      filter_text command(:visible_text)
    end

    def property(name)
      command :property, name
    end

    def [](name)
      # Although the attribute matters, the property is consistent. Return that in
      # preference to the attribute for links and images.
      if (tag_name == 'img' and name == 'src') or (tag_name == 'a' and name == 'href' )
         #if attribute exists get the property
         value = command(:attribute, name) && command(:property, name)
         return value
      end

      value = property(name)
      value = command(:attribute, name) if value.nil? || value.is_a?(Hash)

      value
    end

    def attributes
      command :attributes
    end

    def value
      command :value
    end

    def set(value)
      if tag_name == 'input'
        case self[:type]
        when 'radio'
          click
        when 'checkbox'
          click if value != checked?
        when 'file'
          files = value.respond_to?(:to_ary) ? value.to_ary.map(&:to_s) : value.to_s
          command :select_file, files
        else
          command :set, value.to_s
        end
      elsif tag_name == 'textarea'
        command :set, value.to_s
      elsif self[:contenteditable] == 'true'
        command :delete_text
        send_keys(value.to_s)
      end
    end

    def select_option
      command :select, true
    end

    def unselect_option
      command(:select, false) or
      raise(Capybara::UnselectNotAllowed, "Cannot unselect option from single select box.")
    end

    def tag_name
      @tag_name ||= command(:tag_name)
    end

    def visible?
      command :visible?
    end

    def checked?
      self[:checked]
    end

    def selected?
      self[:selected]
    end

    def disabled?
      command :disabled?
    end

    def click
      command :click
    end

    def right_click
      command :right_click
    end

    def double_click
      command :double_click
    end

    def hover
      command :hover
    end

    def drag_to(other)
      command :drag, other.id
    end

    def drag_by(x, y)
      command :drag_by, x, y
    end

    def trigger(event)
      command :trigger, event
    end

    def ==(other)
      command :equals, other.id
    end

    def send_keys(*keys)
      command :send_keys, keys
    end
    alias_method :send_key, :send_keys

    def path
      command :path
    end

    private

    def filter_text(text)
      Capybara::Helpers.normalize_whitespace(text.to_s)
    end
  end
end
