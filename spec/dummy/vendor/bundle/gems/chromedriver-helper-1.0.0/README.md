# chromedriver-helper

[![Build status](https://api.travis-ci.org/flavorjones/chromedriver-helper.svg)](https://travis-ci.org/flavorjones/chromedriver-helper)

Easy installation and use of [chromedriver](https://sites.google.com/a/chromium.org/chromedriver/), the Chromium project's
selenium webdriver adapter.

* [http://github.com/flavorjones/chromedriver-helper](http://github.com/flavorjones/chromedriver-helper)


# Description

`chromedriver-helper` installs an executable, `chromedriver`, in your
gem path.

This script will, if necessary, download the appropriate binary for
your platform and install it into `~/.chromedriver-helper`, then exec
it. Easy peasy!

chromedriver is fast. By my unscientific benchmark, it's around 20%
faster than webdriver + Firefox 8. You should use it!


# Usage

If you're using Bundler and Capybara, it's as easy as:

    # Gemfile
    gem "chromedriver-helper"

then, in your specs:

    Capybara.register_driver :selenium do |app|
      Capybara::Selenium::Driver.new(app, :browser => :chrome)
    end


# Updating Chromedriver

If you'd like to force-upgrade to the latest version of chromedriver,
run the script `chromedriver-update` that also comes packaged with
this gem.

This might be necessary on platforms on which Chrome auto-updates,
which has been known to introduce incompatibilities with older
versions of chromedriver (see
[Issue #3](https://github.com/flavorjones/chromedriver-helper/issues/3)
for an example).


# Support

The code lives at
[http://github.com/flavorjones/chromedriver-helper](http://github.com/flavorjones/chromedriver-helper).
Open a Github Issue, or send a pull request! Thanks! You're the best.


# License

MIT licensed, see LICENSE.txt for full details.


# Credit

The idea for this gem comes from @brianhempel's project
`chromedriver-gem` which, despite the name, is not currently published
on http://rubygems.org/.

Some improvements on the idea were taken from the installation process
for standalone Phusion Passenger.
