We love pull requests from everyone. We expect users to follow our
[code of conduct] while submitting code or comments.

[code of conduct]: https://thoughtbot.com/open-source-code-of-conduct

## Dependencies

Some of the tests depend on the `identify` command that comes with Imagemagick.
Imagemagick can be installed via [homebrew](http://mxcl.github.com/homebrew/) on
Mac OS X:

    brew install imagemagick

If you prefer, you can use a [Vagrant](http://www.vagrantup.com/) virtual
machine. The Vagrantfile in the capybara-webkit repository will get you up and
running with all the development dependencies:

    gem install vagrant
    vagrant up
    vagrant ssh
    cd /vagrant
    rake

## Contributing

1. Fork the repo.

2. Run the tests. We only take pull requests with passing tests, and it's great
to know that you have a clean slate: `bundle && bundle exec rake`

3. Add a test for your change. Only refactoring and documentation changes
require no new tests. If you are adding functionality or fixing a bug, we need
a test!

4. Make the test pass.

5. Push to your fork and submit a pull request.


At this point you're waiting on us. We like to at least comment on, if not
accept, pull requests within three business days (and, typically, one business
day). We may suggest some changes or improvements or alternatives.

Some things that will increase the chance that your pull request is accepted,
taken straight from the Ruby on Rails guide:

* Use Rails idioms and helpers
* Include tests that fail without your code, and pass with it
* Update the documentation, the surrounding one, examples elsewhere, guides,
  whatever is affected by your contribution

Syntax:

* Two spaces, no tabs.
* No trailing whitespace. Blank lines should not have any space.
* Prefer &&/|| over and/or.
* MyClass.my_method(my_arg) not my_method( my_arg ) or my_method my_arg.
* a = b and not a=b.
* Follow the conventions you see used in the source already.

And in case we didn't emphasize it enough: we love tests!
