# Poltergeist - A PhantomJS driver for Capybara #

[![Build Status](https://secure.travis-ci.org/teampoltergeist/poltergeist.png)](http://travis-ci.org/teampoltergeist/poltergeist)

Poltergeist is a driver for [Capybara](https://github.com/jnicklas/capybara). It allows you to
run your Capybara tests on a headless [WebKit](http://webkit.org) browser,
provided by [PhantomJS](http://phantomjs.org/).

**If you're viewing this at https://github.com/teampoltergeist/poltergeist,
you're reading the documentation for the master branch.
[View documentation for the latest release
(1.8.1).](https://github.com/teampoltergeist/poltergeist/tree/v1.8.1)**

## Getting help ##

Questions should be posted [on Stack
Overflow, using the 'poltergeist' tag](http://stackoverflow.com/questions/tagged/poltergeist).

Bug reports should be posted [on
GitHub](https://github.com/teampoltergeist/poltergeist/issues) (and be sure
to read the bug reporting guidance below).

## Installation ##

Add `poltergeist` to your Gemfile, and in your test setup add:

``` ruby
require 'capybara/poltergeist'
Capybara.javascript_driver = :poltergeist
```

If you were previously using the `:rack_test` driver, be aware that
your app will now run in a separate thread and this can have
consequences for transactional tests. [See the Capybara README for more
detail](https://github.com/jnicklas/capybara/blob/master/README.md#transactions-and-database-setup).

## Installing PhantomJS ##

You need at least PhantomJS 1.8.1.  There are *no other external
dependencies* (you don't need Qt, or a running X server, etc.)

### Mac ###

* *Homebrew*: `brew install phantomjs`
* *MacPorts*: `sudo port install phantomjs`
* *Manual install*: [Download this](https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-macosx.zip)

### Linux ###

* Download the [32 bit](https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-i686.tar.bz2)
or [64 bit](https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-linux-x86_64.tar.bz2)
binary.
* Extract the tarball and copy `bin/phantomjs` into your `PATH`

### Windows ###
* Download the [precompiled binary](https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-windows.zip)
for Windows

### Manual compilation ###

Do this as a last resort if the binaries don't work for you. It will
take quite a long time as it has to build WebKit.

* Download [the source tarball](https://bitbucket.org/ariya/phantomjs/downloads/phantomjs-1.9.8-source.zip)
* Extract and cd in
* `./build.sh`

(See also the [PhantomJS building
guide](http://phantomjs.org/build.html).)

## Compatibility ##

Poltergeist runs on MRI 1.9, JRuby 1.9 and Rubinius 1.9. Poltergeist
and PhantomJS are currently supported on Mac OS X, Linux, and Windows
platforms.

Ruby 1.8 is no longer supported. The last release to support Ruby 1.8
was 1.0.2, so you should use that if you still need Ruby 1.8 support.

## Running on a CI ##

There are no special steps to take. You don't need Xvfb or any running X
server at all.

[Travis CI](https://travis-ci.org/) has PhantomJS pre-installed.

Depending on your tests, one thing that you may need is some fonts. If
you're getting errors on a CI that don't occur during development then
try taking some screenshots - it may well be missing fonts throwing
things off kilter. Your distro will have various font packages available
to install.

## What's supported? ##

Poltergeist supports all the mandatory features for a Capybara driver,
and the following optional features:

* `page.evaluate_script` and `page.execute_script`
* `page.within_frame`
* `page.status_code`
* `page.response_headers`
* `page.save_screenshot`
* `page.driver.render_base64(format, options)`
* `page.driver.scroll_to(left, top)`
* `page.driver.basic_authorize(user, password)`
* `element.native.send_keys(*keys)`
* window API
* cookie handling
* drag-and-drop

There are some additional features:

### Taking screenshots with some extensions ###

You can grab screenshots of the page at any point by calling
`save_screenshot('/path/to/file.png')` (this works the same way as the PhantomJS
render feature, so you can specify other extensions like `.pdf`, `.gif`, etc.)
Just in case you render pdf it's might be worth to set `driver.paper_size=` with
settings provided by PhantomJS in [here](https://github.com/ariya/phantomjs/wiki/API-Reference-WebPage#wiki-webpage-paperSize)

By default, only the viewport will be rendered (the part of the page that is in
view). To render the entire page, use `save_screenshot('/path/to/file.png',
:full => true)`.

You also have an ability to render selected element. Pass option `selector` with
any valid element selector to make a screenshot bounded by that element
`save_screenshot('/path/to/file.png', :selector => '#id')`.

If you need for some reasons base64 encoded screenshot you can simply call
`render_base64` that will return you encoded image. Additional options are the
same as for `save_screenshot` except the first argument which is format (:png by
default, acceptable :png, :gif, :jpeg).

### Clicking precise coordinates ###

Sometimes its desirable to click a very specific area of the screen. You can accomplish this with
`page.driver.click(x, y)`, where x and y are the screen coordinates.

### Remote debugging (experimental) ###

If you use the `:inspector => true` option (see below), remote debugging
will be enabled.

When this option is enabled, you can insert `page.driver.debug` into
your tests to pause the test and launch a browser which gives you the
WebKit inspector to view your test run with.

You can register this debugger driver with a different name and set it
as the current javascript driver. By example, in your helper file:

```ruby
Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, :inspector => true)
end

# Capybara.javascript_driver = :poltergeist
Capybara.javascript_driver = :poltergeist_debug
```

[Read more
here](http://jonathanleighton.com/articles/2012/poltergeist-0-6-0/)

### Manipulating request headers ###

You can manipulate HTTP request headers with these methods:

``` ruby
page.driver.headers # => {}
page.driver.headers = { "User-Agent" => "Poltergeist" }
page.driver.add_headers("Referer" => "https://example.com")
page.driver.headers # => { "User-Agent" => "Poltergeist", "Referer" => "https://example.com" }
```

Notice that `headers=` will overwrite already set headers. You should use
`add_headers` if you want to add a few more. These headers will apply to all
subsequent HTTP requests (including requests for assets, AJAX, etc). They will
be automatically cleared at the end of the test. You have ability to set headers
only for the initial request:

``` ruby
page.driver.headers = { "User-Agent" => "Poltergeist" }
page.driver.add_header("Referer", "http://example.com", permanent: false)
page.driver.headers # => { "User-Agent" => "Poltergeist", "Referer" => "http://example.com" }
visit(login_path)
page.driver.headers # => { "User-Agent" => "Poltergeist" }
```

This way your temporary headers will be sent only for the initial request, all
subsequent request will only contain your permanent headers.

### Inspecting network traffic ###

You can inspect the network traffic (i.e. what resources have been
loaded) on the current page by calling `page.driver.network_traffic`.
This returns an array of request objects. A request object has a
`response_parts` method containing data about the response chunks.
Please note that network traffic is not cleared when you visit new page.
You can manually clear the network traffic by calling `page.driver.clear_network_traffic`
or `page.driver.reset`

### Manipulating cookies ###

The following methods are used to inspect and manipulate cookies:

* `page.driver.cookies` - a hash of cookies accessible to the current
  page. The keys are cookie names. The values are `Cookie` objects, with
  the following methods: `name`, `value`, `domain`, `path`, `secure?`,
  `httponly?`, `expires`.
* `page.driver.set_cookie(name, value, options = {})` - set a cookie.
  The options hash can take the following keys: `:domain`, `:path`,
  `:secure`, `:httponly`, `:expires`. `:expires` should be a `Time`
  object.
* `page.driver.remove_cookie(name)` - remove a cookie
* `page.driver.clear_cookies` - clear all cookies

### Sending keys ###

There's an ability to send arbitrary keys to the element:

``` ruby
element = find('input#id')
element.native.send_key('String')
```

or even more complicated:

``` ruby
element.native.send_keys('H', 'elo', :Left, 'l') # => 'Hello'
element.native.send_key(:Enter) # triggers Enter key
```
Since it's implemented natively in PhantomJS this will exactly imitate user
behavior.
See more about [sendEvent](http://phantomjs.org/api/webpage/method/send-event.html) and
[PhantomJS keys](https://github.com/ariya/phantomjs/commit/cab2635e66d74b7e665c44400b8b20a8f225153a)

## Customization ##

You can customize the way that Capybara sets up Poltergeist via the following code in your
test setup:

``` ruby
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, options)
end
```

`options` is a hash of options. The following options are supported:

*   `:phantomjs` (String) - A custom path to the phantomjs executable
*   `:debug` (Boolean) - When true, debug output is logged to `STDERR`.
    Some debug info from the PhantomJS portion of Poltergeist is also
    output, but this goes to `STDOUT` due to technical limitations.
*   `:logger` (Object responding to `puts`) - When present, debug output is written to this object
*   `:phantomjs_logger` (`IO` object) - Where the `STDOUT` from PhantomJS is written to. This is
    where your `console.log` statements will show up. Default: `STDOUT`
*   `:timeout` (Numeric) - The number of seconds we'll wait for a response
    when communicating with PhantomJS. Default is 30.
*   `:inspector` (Boolean, String) - See 'Remote Debugging', above.
*   `:js_errors` (Boolean) - When false, Javascript errors do not get re-raised in Ruby.
*   `:window_size` (Array) - The dimensions of the browser window in which to test, expressed
    as a 2-element array, e.g. [1024, 768]. Default: [1024, 768]
*   `:phantomjs_options` (Array) - Additional [command line options](http://phantomjs.org/api/command-line.html)
    to be passed to PhantomJS, e.g. `['--load-images=no', '--ignore-ssl-errors=yes']`
*   `:extensions` (Array) - An array of JS files to be preloaded into
    the phantomjs browser. Useful for faking unsupported APIs.
*   `:port` (Fixnum) - The port which should be used to communicate
    with the PhantomJS process. Defaults to a random open port.

### URL Blacklisting ###

Poltergeist supports URL blacklisting which allows you
to prevent scripts from running on designated domains. If you are experiencing
slower run times, consider creating a URL blacklist of domains that are not
essential to your testing environment, such as ad networks or analytics.

```ruby
page.driver.browser.url_blacklist = ['http://www.example.com']
```

Make sure you set it before each running test, because this setting's cleaned
up when capybara does reset.

## Troubleshooting ##

Unfortunately, the nature of full-stack testing is that things can and
do go wrong from time to time. This section aims to highlight a number
of common problems and provide ideas about how you can work around them.

### DeadClient errors ###

Sometimes PhantomJS crashes during a test. There are basically two kinds
of crashes: those that can be reproduced every time, and those that
occur sporadically and are not easily reproduced.

If your crash happens every time, you should read the [PhantomJS crash
reporting
guide](http://phantomjs.org/crash-reporting.html) and file
a bug against PhantomJS. Feel free to also file a bug against
Poltergeist in case there are workarounds that can be implemented within
Poltergeist. Also, if lots of Poltergeist users are experiencing the
same crash then fixing it will move up the priority list.

If your crash is sporadic, there is less that can be done. Often these
issues are very complicated and difficult to track down. It may be that
the crash has already been fixed in a newer version of WebKit that will
eventually find its way into PhantomJS. It's still worth reporting your
bug against PhantomJS, but it's probably not worth filing a bug against
Poltergeist as there's not much we can do.

If you experience sporadic crashes a lot, it may be worth configuring
your CI to automatically re-run failing tests before reporting a failed
build.

### MouseEventFailed errors ###

When Poltergeist clicks on an element, rather than generating a DOM
click event, it actually generates a "proper" click. This is much closer
to what happens when a real user clicks on the page - but it means that
Poltergeist must scroll the page to where the element is, and work out
the correct co-ordinates to click. If the element is covered up by
another element, the click will fail (this is a good thing - because
your user won't be able to click a covered up element either).

Sometimes there can be issues with this behavior. If you have problems,
it's worth taking screenshots of the page and trying to work out what's
going on. If your click is failing, but you're not getting a
`MouseEventFailed` error, then you can turn on the `:debug` option and look
in the output to see what co-ordinates Poltergeist is using for the
click. You can then cross-reference this with a screenshot to see if
something is obviously wrong.

If you can't figure out what's going on and just want to work around the
problem so you can get on with life, consider using a DOM click
event. For example, if this code is failing:

``` ruby
click_button "Save"
```

Then try:

``` ruby
find_button("Save").trigger('click')
```

### Timing problems ###

Sometimes tests pass and fail sporadically. This is often because there
is some problem synchronising events properly. It's often
straightforward to verify this by adding `sleep` statements into your
test to allow sufficient time for the page to settle.

If you have these types of problems, read through the [Capybara
documentation on asynchronous
Javascript](https://github.com/jnicklas/capybara#asynchronous-javascript-ajax-and-friends)
which explains the tools that Capybara provides for dealing with this.

### Memory leak ###

If you run a few capybara sessions manually please make sure you've called
`session.driver.quit` when you don't need session anymore. Forgetting about this
causes memory leakage and your system's resources can be exhausted earlier than
you may expect.

### General troubleshooting hints ###

* Configure Poltergeist with `:debug` turned on so you can see its
  communication with PhantomJS.
* Take screenshots to figure out what the state of your page is when the
  problem occurs.
* Use the remote web inspector in case it provides any useful insight
* Consider downloading the Poltergeist source and using `console.log`
  debugging to figure out what's going on inside PhantomJS. (This will
  require an understanding of the Poltergeist source code and PhantomJS,
  so it's only for the committed!)

### Filing a bug ###

If you can provide specific steps to reproduce your problem, or have
specific information that might help other help you track down the
problem, then please file a bug on Github.

Include as much information as possible. For example:

* Specific steps to reproduce where possible (failing tests are even
  better)
* The output obtained from running Poltergeist with `:debug` turned on
* Screenshots
* Stack traces if there are any Ruby on Javascript exceptions generated
* The Poltergeist and PhantomJS version numbers used
* The operating system name and version used

## Changes ##

Version history and a list of next-release features and fixes can be found in
the [changelog](CHANGELOG.md).

## License ##

Copyright (c) 2011-2015 Jonathan Leighton

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
