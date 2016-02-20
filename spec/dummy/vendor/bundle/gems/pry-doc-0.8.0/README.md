![Pry Doc][logo]

* Repository: [https://github.com/pry/pry-doc][repo]
* Wiki: [https://github.com/pry/pry-doc/wiki][wiki]
* [![Build Status](https://travis-ci.org/pry/pry-doc.svg?branch=master)](https://travis-ci.org/pry/pry-doc)

Description
-----------

Pry Doc is a plugin for [Pry][pry]. It provides extended documentation support
for Pry.

Installation
------------

All you need is to install the gem. The `pry-doc` plugin will be detected and
used automatically.

    gem install pry-doc

Synopsis
--------

Pry Doc extends two core Pry commands: `show-doc` and `show-source` (aliased as
`?` and `$` respectively).

For example, in vanilla Pry it’s impossible to get the documentation for the
`loop` method (it’s a method, by the way). However, Pry Doc solves that problem.

![show-source][show-doc]

Let's check the source code of the `loop` method.

![show-doc][show-source]

Generally speaking, you can retrieve most of the MRI documentation and
accompanying source code. Pry Doc is also smart enough to get any documentation
for methods and classes implemented in C.

Limitations
-----------

Pry Doc supports the following Rubies:

* MRI 1.9
* MRI 2.0
* MRI 2.1

Getting Help
------------

Simply file an issue or visit `#pry` at `irc.freenode.net`.

License
-------

The project uses the MIT Licencse. See LICENSE file for more information.

[logo]: http://img-fotki.yandex.ru/get/6724/98991937.13/0_9faaa_26ec83af_orig "Pry Doc"
[pry]: https://github.com/pry/pry
[show-source]: http://img-fotki.yandex.ru/get/9303/98991937.13/0_9faac_aa86e189_orig "show-source extended by Pry Doc"
[show-doc]: http://img-fotki.yandex.ru/get/9058/98991937.13/0_9faab_68d7a43a_orig "show-doc extended by Pry Doc"
[repo]: https://github.com/pry/pry-doc
[wiki]: https://github.com/pry/pry-doc/wiki
