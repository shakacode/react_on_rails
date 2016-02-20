require "json"
require "capybara/webkit/errors"

module Capybara::Webkit
  class Browser
    def initialize(connection)
      @connection = connection
    end

    def authenticate(username, password)
      command("Authenticate", username, password)
    end

    def enable_logging
      command "EnableLogging"
    end

    def visit(url)
      command "Visit", url
    end

    def header(key, value)
      command("Header", key, value)
    end

    def title
      command("Title")
    end

    def find_xpath(query)
      command("FindXpath", query).split(",")
    end

    def find_css(query)
      command("FindCss", query).split(",")
    end

    def reset!
      command("Reset")
    end

    def body
      command("Body")
    end

    def status_code
      command("Status").to_i
    end

    def console_messages
      JSON.parse(command("ConsoleMessages")).map do |message|
        message.inject({}) { |m,(k,v)| m.merge(k.to_sym => v) }
      end
    end

    def error_messages
      console_messages.select do |message|
        message[:message] =~ /Error:/
      end
    end

    def alert_messages
      JSON.parse(command("JavascriptAlertMessages"))
    end

    def confirm_messages
      JSON.parse(command("JavascriptConfirmMessages"))
    end

    def prompt_messages
      JSON.parse(command("JavascriptPromptMessages"))
    end

    def response_headers
      JSON.parse(command("Headers"))
    end

    def current_url
      command("CurrentUrl")
    end

    def frame_focus(selector=nil)
      if selector.respond_to?(:base)
        selector.base.invoke('focus')
      elsif selector.is_a? Fixnum
        command("FrameFocus", "", selector.to_s)
      elsif selector
        command("FrameFocus", selector)
      else
        command("FrameFocus")
      end
    end

    def ignore_ssl_errors
      command("IgnoreSslErrors")
    end

    def set_skip_image_loading(skip_image_loading)
      command("SetSkipImageLoading", skip_image_loading)
    end

    def window_focus(selector)
      command("WindowFocus", selector)
    end

    def window_open
      command("WindowOpen")
    end

    def window_close(selector)
      command("WindowClose", selector)
    end

    def window_resize(handle, width, height)
      command("WindowResize", handle, width.to_i, height.to_i)
    end

    def window_size(handle)
      JSON.parse(command("WindowSize", handle))
    end

    def window_maximize(handle)
      command("WindowMaximize", handle)
    end

    def get_window_handles
      JSON.parse(command('GetWindowHandles'))
    end

    def window_handles
      warn '[DEPRECATION] Capybara::Webkit::Browser#window_handles ' \
        'is deprecated. Please use Capybara::Session#windows instead.'
      get_window_handles
    end

    def get_window_handle
      command('GetWindowHandle')
    end

    def window_handle
      warn '[DEPRECATION] Capybara::Webkit::Browser#window_handle ' \
        'is deprecated. Please use Capybara::Session#current_window instead.'
      get_window_handle
    end

    def accept_confirm(options)
      command("SetConfirmAction", "Yes", options[:text])
    end

    def accept_js_confirms
      command("SetConfirmAction", "Yes")
    end

    def reject_confirm(options)
      command("SetConfirmAction", "No", options[:text])
    end

    def reject_js_confirms
      command("SetConfirmAction", "No")
    end

    def accept_prompt(options)
      if options[:with]
        command("SetPromptAction", "Yes", options[:text], options[:with])
      else
        command("SetPromptAction", "Yes", options[:text])
      end
    end

    def accept_js_prompts
      command("SetPromptAction", "Yes")
    end

    def reject_prompt(options)
      command("SetPromptAction", "No", options[:text])
    end

    def reject_js_prompts
      command("SetPromptAction", "No")
    end

    def set_prompt_text_to(string)
      command("SetPromptText", string)
    end

    def clear_prompt_text
      command("ClearPromptText")
    end

    def accept_alert(options)
      command("AcceptAlert", options[:text])
    end

    def find_modal(id)
      command("FindModal", id)
    end

    def url_blacklist=(black_list)
      warn '[DEPRECATION] Capybara::Webkit::Browser#url_blacklist= ' \
        'is deprecated. Please use page.driver.block_url instead.'
      command("SetUrlBlacklist", *Array(black_list))
    end

    def command(name, *args)
      @connection.puts name
      @connection.puts args.size
      args.each do |arg|
        @connection.puts arg.to_s.bytesize
        @connection.print arg.to_s
      end
      check
      read_response
    rescue SystemCallError => exception
      @connection.restart
      raise(Capybara::Webkit::CrashError, <<-MESSAGE.strip)
The webkit_server process crashed!

  #{exception.message}

This is a bug in capybara-webkit. For help with this crash, please visit:

https://github.com/thoughtbot/capybara-webkit/wiki/Reporting-Crashes
      MESSAGE
    end

    def evaluate_script(script)
      json = command('Evaluate', script)
      JSON.parse("[#{json}]").first
    end

    def execute_script(script)
      command('Execute', script)
    end

    def render(path, width, height)
      command "Render", path, width, height
    end

    def timeout=(timeout_in_seconds)
      command "SetTimeout", timeout_in_seconds
    end

    def timeout
      command("GetTimeout").to_i
    end

    def set_cookie(cookie)
      command "SetCookie", cookie
    end

    def clear_cookies
      command "ClearCookies"
    end

    def get_cookies
      command("GetCookies").lines.map{ |line| line.strip }.select{ |line| !line.empty? }
    end

    def set_proxy(options = {})
      options = default_proxy_options.merge(options)
      command("SetProxy", options[:host], options[:port], options[:user], options[:pass])
    end

    def clear_proxy
      command("SetProxy")
    end

    def version
      command("Version")
    end

    def go_back
      command("GoBack")
    end

    def go_forward
      command("GoForward")
    end

    def allow_url(url)
      command("AllowUrl", url)
    end

    def block_url(url)
      command("BlockUrl", url)
    end

    def block_unknown_urls
      command("SetUnknownUrlMode", "block")
    end

    def allow_unknown_urls
      allow_url("*")
    end

    private

    def check
      result = @connection.gets
      result.strip! if result

      if result.nil?
        raise NoResponseError, "No response received from the server."
      elsif result != 'ok'
        raise JsonError.new(read_response)
      end

      result
    end

    def read_response
      response_length = @connection.gets.to_i
      if response_length > 0
        response = @connection.read(response_length)
        response.force_encoding("UTF-8") if response.respond_to?(:force_encoding)
        response
      else
        ""
      end
    end

    def default_proxy_options
      {
        :host => "localhost",
        :port => "0",
        :user => "",
        :pass => ""
      }
    end
  end
end
