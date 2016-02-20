## 3.3.0 (2015-11-05)

- Improvements:
  * Up to date dependencies, including byebug 8.0 series.
  * Faster debugger thanks to @k0kubun (#80).

- Bugfixes:
  * Fix encoding error in gemspec file (#70).


## 3.2.0 (2015-07-18)

- Improvements:
  * Allow continue to receive a line number argument (#56).
  * Refactorings + RuboCop.
  * Up to date dependencies.

- Bugfixes:
  * Don't conflict with `break` and `next` Ruby keywords inside multiline
statements (#44).

- Removals:
  * `breaks` command. It was broken anyways (#47).


## 3.1.0 (2015-04-14)

- Improvements:
  * Add frame nav commands up, down and frame.


## 3.0.1 (2015-04-02)

- Improvements:
  * Fix several formatting and alignment issues.


## 3.0.0 (2015-02-02)

- Improvements:
  * Adds RuboCop to enforce a consistent code style.
  * Several refactorings to keep code simpler.

- Bugfixes:
  * `binding.pry` would not stop at the correct place when called at the last
line of a method/block.

- Removals:
  * Stepping aliases for `next` (`n`), `step` (`s`), `finish` (`f`) and
`continue` (`c`). See #34.


## 2.0.0 (2014-01-09)

- Improvements:
  * Compatibility with byebug 3
  * Now pry starts at the first line after binding.pry, not at binding.pry
- Bugfixes:
  * 'continue' doesn't finish pry instance (issue #13)


## 1.3.3 (2014-25-06)

* Relaxes pry dependency to support pry 0.10 series and further minor version
level releases.


## 1.3.2 (2014-24-02)

* Bumps byebug dependency to get rid of bug in byebug.


## 1.3.1 (2014-08-02)

* Fix #22 (thanks @andreychernih)


## 1.3.0 (2014-05-02)

* Add breakpoints on method names (thanks @andreychernih & @palkan)
* Fix "undefined method `interface`" error (huge thanks to @andreychernih)


## 1.2.1 (2013-30-12)

* Fix for "uncaught throw :breakout_nav" (thanks @lukebergen)


## 1.2.0 (2013-24-09)

* Compatibility with byebug's 2.x series


## 1.1.2 (2013-11-07)

* Allow pry-byebug to use backwards compatible versions of byebug


## 1.1.1 (2013-02-07)

* Adds some initial tests to the test suite
* Fixes bug when doing "step n" or "next n" where n > 1 right after binding.pry


## 1.1.0 (2013-06-06)

* Adds a test suite (thanks @teeparham!)
* Uses byebug ~> 1.4.0
* Uses s, n, f and c aliases by default (thanks @jgakos!)


## 1.0.0, 1.0.1 (2013-05-07)

* Forked from [pry-debugger](https://github.com/nixme/pry-debugger) to support
  byebug
* Dropped pry-remote support


## 0.2.2 (2013-03-07)

* Relaxed [byebug][byebug] dependency.


## 0.2.1 (2012-12-26)

* Support breakpoints on methods defined in the pry console. (@banister)
* Fix support for specifying breakpoints by *file:line_number*. (@nviennot)
* Validate breakpoint conditionals are real Ruby expressions.
* Support for debugger ~> 1.2.0. (@jshou)
* Safer `alias_method_chain`-style patching of `Pry.start` and
  `PryRemote::Server#teardown`. (@benizi)


## 0.2.0 (2012-06-11)

* Breakpoints
* **finish** command
* Internal cleanup and bug fixes


## 0.1.0 (2012-06-07)

* First release. **step**, **next**, and **continue** commands.
  [pry-remote 0.1.4][pry-remote] support.
