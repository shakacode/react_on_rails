require 'webrick/cookie'

# A simple cookie jar implementation.
# Does not take special cookie attributes
# into account like expire, max-age, httponly, secure
class Capybara::Webkit::CookieJar
  attr_reader :browser

  def initialize(browser)
    @browser = browser
  end

  def [](*args)
    cookie = find(*args)
    cookie && cookie.value
  end

  def find(name, domain = nil, path = "/")
    # we are sorting by path size because more specific paths take
    # precendence
    cookies.sort_by { |c| -c.path.size }.find { |c|
      c.name.downcase == name.downcase &&
      (!domain || valid_domain?(c, domain)) &&
      (!path   || valid_path?(c, path))
    }
  end

 protected

  def valid_domain?(cookie, domain)
    ends_with?(("." + domain).downcase,
               normalize_domain(cookie.domain).downcase)
  end

  def normalize_domain(domain)
    domain = "." + domain unless domain[0,1] == "."
    domain
  end

  def valid_path?(cookie, path)
    starts_with?(path, cookie.path)
  end

  def ends_with?(str, suffix)
    str[-suffix.size..-1] == suffix
  end

  def starts_with?(str, prefix)
    str[0, prefix.size] == prefix
  end

  def cookies
    browser.get_cookies.map { |c| WEBrick::Cookie.parse_set_cookie(c) }
  end
end
