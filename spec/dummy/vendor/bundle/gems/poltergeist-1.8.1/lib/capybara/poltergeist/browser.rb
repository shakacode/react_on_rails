require "capybara/poltergeist/errors"
require "capybara/poltergeist/command"
require 'multi_json'
require 'time'

module Capybara::Poltergeist
  class Browser
    ERROR_MAPPINGS = {
      'Poltergeist.JavascriptError' => JavascriptError,
      'Poltergeist.FrameNotFound'   => FrameNotFound,
      'Poltergeist.InvalidSelector' => InvalidSelector,
      'Poltergeist.StatusFailError' => StatusFailError,
      'Poltergeist.NoSuchWindowError' => NoSuchWindowError
    }

    attr_reader :server, :client, :logger

    def initialize(server, client, logger = nil)
      @server = server
      @client = client
      @logger = logger
    end

    def restart
      server.restart
      client.restart

      self.debug = @debug if defined?(@debug)
      self.js_errors = @js_errors if defined?(@js_errors)
      self.extensions = @extensions if @extensions
    end

    def visit(url)
      command 'visit', url
    end

    def current_url
      command 'current_url'
    end

    def status_code
      command 'status_code'
    end

    def body
      command 'body'
    end

    def source
      command 'source'
    end

    def title
      command 'title'
    end

    def parents(page_id, id)
      command 'parents', page_id, id
    end

    def find(method, selector)
      result = command('find', method, selector)
      result['ids'].map { |id| [result['page_id'], id] }
    end

    def find_within(page_id, id, method, selector)
      command 'find_within', page_id, id, method, selector
    end

    def all_text(page_id, id)
      command 'all_text', page_id, id
    end

    def visible_text(page_id, id)
      command 'visible_text', page_id, id
    end

    def delete_text(page_id, id)
      command 'delete_text', page_id, id
    end

    def property(page_id, id, name)
      command 'property', page_id, id, name.to_s
    end

    def attributes(page_id, id)
      command 'attributes', page_id, id
    end

    def attribute(page_id, id, name)
      command 'attribute', page_id, id, name.to_s
    end

    def value(page_id, id)
      command 'value', page_id, id
    end

    def set(page_id, id, value)
      command 'set', page_id, id, value
    end

    def select_file(page_id, id, value)
      command 'select_file', page_id, id, value
    end

    def tag_name(page_id, id)
      command('tag_name', page_id, id).downcase
    end

    def visible?(page_id, id)
      command 'visible', page_id, id
    end

    def disabled?(page_id, id)
      command 'disabled', page_id, id
    end

    def click_coordinates(x, y)
      command 'click_coordinates', x, y
    end

    def evaluate(script)
      command 'evaluate', script
    end

    def execute(script)
      command 'execute', script
    end

    def within_frame(handle, &block)
      if handle.is_a?(Capybara::Node::Base)
        command 'push_frame', [handle.native.page_id, handle.native.id]
      else
        command 'push_frame', handle
      end

      yield
    ensure
      command 'pop_frame'
    end

    def window_handle
      command 'window_handle'
    end

    def window_handles
      command 'window_handles'
    end

    def switch_to_window(handle)
      command 'switch_to_window', handle
    end

    def open_new_window
      command 'open_new_window'
    end

    def close_window(handle)
      command 'close_window', handle
    end

    def find_window_handle(locator)
      return locator if window_handles.include? locator

      handle = command 'window_handle', locator
      raise noSuchWindowError unless handle
      return handle
    end

    def within_window(locator, &block)
      original = window_handle
      handle = find_window_handle(locator)
      switch_to_window(handle)
      yield
    ensure
      switch_to_window(original)
    end

    def click(page_id, id)
      command 'click', page_id, id
    end

    def right_click(page_id, id)
      command 'right_click', page_id, id
    end

    def double_click(page_id, id)
      command 'double_click', page_id, id
    end

    def hover(page_id, id)
      command 'hover', page_id, id
    end

    def drag(page_id, id, other_id)
      command 'drag', page_id, id, other_id
    end

    def drag_by(page_id, id, x, y)
      command 'drag_by', page_id, id, x, y
    end

    def select(page_id, id, value)
      command 'select', page_id, id, value
    end

    def trigger(page_id, id, event)
      command 'trigger', page_id, id, event.to_s
    end

    def reset
      command 'reset'
    end

    def scroll_to(left, top)
      command 'scroll_to', left, top
    end

    def render(path, options = {})
      check_render_options!(options)
      command 'render', path.to_s, !!options[:full], options[:selector]
    end

    def render_base64(format, options = {})
      check_render_options!(options)
      command 'render_base64', format.to_s, !!options[:full], options[:selector]
    end

    def set_zoom_factor(zoom_factor)
      command 'set_zoom_factor', zoom_factor
    end

    def set_paper_size(size)
      command 'set_paper_size', size
    end

    def resize(width, height)
      command 'resize', width, height
    end

    def send_keys(page_id, id, keys)
      command 'send_keys', page_id, id, normalize_keys(keys)
    end

    def path(page_id, id)
      command 'path', page_id, id
    end

    def network_traffic
      command('network_traffic').values.map do |event|
        NetworkTraffic::Request.new(
          event['request'],
          event['responseParts'].map { |response| NetworkTraffic::Response.new(response) },
          event['error'] ? NetworkTraffic::Error.new(event['error']) : nil
        )
      end
    end

    def clear_network_traffic
      command('clear_network_traffic')
    end

    def equals(page_id, id, other_id)
      command('equals', page_id, id, other_id)
    end

    def get_headers
      command 'get_headers'
    end

    def set_headers(headers)
      command 'set_headers', headers
    end

    def add_headers(headers)
      command 'add_headers', headers
    end

    def add_header(header, permanent)
      command 'add_header', header, permanent
    end

    def response_headers
      command 'response_headers'
    end

    def cookies
      Hash[command('cookies').map { |cookie| [cookie['name'], Cookie.new(cookie)] }]
    end

    def set_cookie(cookie)
      if cookie[:expires]
        cookie[:expires] = cookie[:expires].to_i * 1000
      end

      command 'set_cookie', cookie
    end

    def remove_cookie(name)
      command 'remove_cookie', name
    end

    def clear_cookies
      command 'clear_cookies'
    end

    def cookies_enabled=(flag)
      command 'cookies_enabled', !!flag
    end

    def set_http_auth(user, password)
      command 'set_http_auth', user, password
    end

    def js_errors=(val)
      @js_errors = val
      command 'set_js_errors', !!val
    end

    def extensions=(names)
      @extensions = names
      Array(names).each do |name|
        command 'add_extension', name
      end
    end

    def url_blacklist=(blacklist)
      command 'set_url_blacklist', *blacklist
    end

    def debug=(val)
      @debug = val
      command 'set_debug', !!val
    end

    def command(name, *args)
      cmd = Command.new(name, *args)
      log cmd.message

      response = server.send(cmd)
      log response

      json = JSON.load(response)

      if json['error']
        klass = ERROR_MAPPINGS[json['error']['name']] || BrowserError
        raise klass.new(json['error'])
      else
        json['response']
      end
    rescue DeadClient
      restart
      raise
    end

    def go_back
      command 'go_back'
    end

    def go_forward
      command 'go_forward'
    end

    def accept_confirm
      command 'set_confirm_process', true
    end

    def dismiss_confirm
      command 'set_confirm_process', false
    end

    #
    # press "OK" with text (response) or default value
    #
    def accept_prompt(response)
      command 'set_prompt_response', response || false
    end

    #
    # press "Cancel"
    #
    def dismiss_prompt
      command 'set_prompt_response', nil
    end

    def modal_message
      command 'modal_message'
    end

    private

    def log(message)
      logger.puts message if logger
    end

    def check_render_options!(options)
      if !!options[:full] && options.has_key?(:selector)
        warn "Ignoring :selector in #render since :full => true was given at #{caller.first}"
        options.delete(:selector)
      end
    end

    def normalize_keys(keys)
      keys.map do |key|
        case key
        when Array
          # [:Shift, "s"] => { modifier: "shift", key: "S" }
          # [:Ctrl, :Left] => { modifier: "ctrl", key: :Left }
          # [:Ctrl, :Shift, :Left] => { modifier: "ctrl,shift", key: :Left }
          letter = key.pop
          symbol = key.map { |k| k.to_s.downcase }.join(',')

          { modifier: symbol.to_s.downcase, key: letter.capitalize }
        when Symbol
          { key: key.capitalize } # Return a known sequence for PhantomJS
        when String
          key # Plain string, nothing to do
        end
      end
    end
  end
end
