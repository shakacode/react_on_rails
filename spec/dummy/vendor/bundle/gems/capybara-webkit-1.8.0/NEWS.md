New for 1.8.0:

* Allow Capybara 2.6

New for 1.7.1:

* Fix deprecation messages relating to default_wait_time

New for 1.7.0:

* Capybara 2.5 compatibility (except Node#send_keys)
* Update UnknownUrlHandler warning to use non-deprecated methods

New for 1.6.0:

* New, easier, global configuration API.
* Add `page.driver.allow_unknown_urls` to silent all unknown host warnings.
* Add warning for users on Qt 4.
* Fix bug when parsing response headers with values containing colons.
* Allow multiple, different basic authorizations in a single session.
* Caches behave more like Selenium
* Select tag events behave more like Selenium
* Deprecated `driver.browser`
* Provide better behavior and information when the driver crashes

New for 1.5.2:

* Fixes bug where aborted Ajax requests caused a crash during reset.

New for 1.5.1:

* Fixes bug where Ajax requests would continue after a reset, causing native
  alerts to appear for some users and crashes for others.

New for 1.5.0:

* Fixes for OpenBSD
* Disable web page and object memory cache

New for 1.4.1:

* Do not consider data URIs unknown.
* Make sure webkit_server process runs in background.

New for 1.4.0:

* Fix returning invisible text on a hidden page
* Expose INCLUDEPATH and LIBS qmake variables
* Drop support for older Capybara versions
* Introduce allowed, blocked URL filters

New for 1.3.1:

* Inherit from Capybara::Driver::Base for Capybara 2.4.4 compatibility.
* Fix a bug in the modal API which could cause an incorrect modal to be found.

New for 1.3.0:

* Capybara 2.4 compatibility.
* Raise better errors if server fails to start
* Offline application cache support.
* Wildcard URL blacklist support.

New for 1.2.0:
* Capybara 2.3 compatibility.
* Kill webkit_server when parent process closes stdin.

New for 1.1.1:
* Lock capybara dependency to < 2.2.0.

New for 1.1.0:

* Improve messages for ClickFailed errors to aid debugging.
* Fix long load times on Ruby 2.0.0-p195.
* Automatically save screenshots on ClickFailed errors.
* Render a mouse pointer in screenshots for the current mouse location.
* Silent debug messages from Qt.
* Fix OS X keychain bug in Qt 5 related to basic authentication.
* Fix issues visiting URLs with square brackets.
* Fail immediately when trying to install with unsupported versions of Qt.
* Fix race condition leading to InvalidResponseErrors.

New for 1.0.0:

* Fix a memory leak in the logger.
* Add Vagrant configuration.
* Deprecate the stdout option for Connection.
* Make Node#text work for svg elements.
* Add Driver#version to print version info.
* Click elements with native events.
* Fix test failures from warnings.
* Capybara 2.1 compatibility.
* Implement right click.
* Qt 5 compatibility.
* Set text fields using native key events.
* Clear localStorage on reset.

New for 0.14.1:

* Rescue from Errno::ESRCH in the exit hook in case webkit_server has already ended.
* Remove web font override for first-letter and first-line pseudo elements, which was causing issues for some users.
* Restore viewport dimensions after rendering screenshots.

New for 0.14.0:

* URL blacklist support.
* Various fixes for JavaScript console messages.
* Various compilation fixes.
* Fix status code and headers commands for iframes.
* Capybara 2.0 compatibility.
* Driver#render replaced by Session#save_screenshot.
* Driver#source and Driver#body return the HTML representation of the DOM.  Unsupported content is returned as plain text.
* HTML5 multi-file upload support.
* Driver#url and Driver#requested_url removed.
* JavaScipt console messages and alerts are now written to the logger instead of directly to stdout.
* Dropped support for Qt 4.7.
* Fix deadlocks encountered during page load.
* Delete Response objects when commands have timed out.
* Fix an infinite loop when invalid credentials are used for HTTP auth.
* Ensure queued commands start only after pending commands have finished.
* Fix segfaults related to web fonts on OS X.

New for 0.13.0:

* Better detect page load success, and better handle load failures.
* HTTP Basic Auth support.
* within_window support.
* More useful and detailed debugging output.
* Catch up with recent capybara releases.
* Ignore errors from canceled requests.
* Follow how Selenium treats focus and blur form events.
* Control JavaScript prompts from Ruby.
* Each command has a configurable timeout.
* Performance improvements on Linux.
* Support empty `multiple` attributes.

New for 0.12.1:

* Fix integration with newer capybara for the debugging driver.

New for 0.12.0:
* Better windows support
* Support for localStorage
* Added support for oninput event
* Added resize_window method
* Server binds on LocalHost to prevent having to add firewall exceptions
* Reuse NetworkAccessManager to prevent "too many open files" errors
* Response messages are stored as QByteArray to prevent truncating content
* Browser no longer tries to read empty responses (Fixes jruby issues).
* Server will timeout if it can not start

New for 0.11.0:

* Allow interaction with invisible elements
* Use Timeout from stdlib since Capybara.timeout is being removed

New for 0.10.1:

* LANG environment variable is set to en_US.UTF-8 in order to avoid string encoding issues from qmake.
* pro, find_command, and CommandFactory are more structured.
* Changed wiki link and directing platform specific issues to the google group.
* Pass proper keycode value for keypress events.

New for 0.10.0:

* current_url now more closely matches the behavior of Selenium
* custom MAKE, QMAKE, and SPEC options can be set from the environment
* BUG: Selected attribute is no longer removed when selecting/deselecting. Only the property is changed.

New for 0.9.0:

* Raise an error when an invisible element receives #click.
* Raise ElementNotDisplayedError for #drag_to and #select_option when element is invisible.
* Trigger mousedown and mouseup events.
* Model mouse events more closely to the browser.
* Try to detech when a command starts a page load and wait for it to finish
