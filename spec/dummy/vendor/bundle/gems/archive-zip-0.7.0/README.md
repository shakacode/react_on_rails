# Archive::Zip - ZIP Archival Made Easy

Simple, extensible, pure Ruby ZIP archive support.

Basic archive creation and extraction can be handled using only a few methods.
More complex operations involving the manipulation of existing archives in place
(adding, removing, and modifying entries) are also possible with a little more
work.  Even adding advanced features such as new compression codecs are
supported with a moderate amount of effort.

## LINKS

* Homepage :: http://github.com/javanthropus/archive-zip
* Documentation :: http://rdoc.info/gems/archive-zip/frames
* Source :: http://github.com/javanthropus/archive-zip

## DESCRIPTION

Archive::Zip provides a simple Ruby-esque interface to creating, extracting, and
updating ZIP archives.  This implementation is 100% Ruby and loosely modeled on
the archive creation and extraction capabilities of InfoZip's zip and unzip
tools.

## FEATURES

* 100% native Ruby.  (Well, almost... depends on zlib.)
* Archive creation and extraction is supported with only a few lines of code.
* Archives can be updated "in place" or dumped out to other files or pipes.
* Files, symlinks, and directories are supported within archives.
* Unix permission/mode bits are supported.
* Unix user and group ownerships are supported.
* Unix last accessed and last modified times are supported.
* Entry extension (AKA extra field) implementations can be added on the fly.
* Unknown entry extension types are preserved during archive processing.
* The Deflate and Store compression codecs are supported out of the box.
* More compression codecs can be added on the fly.
* Traditional (weak) encryption is supported out of the box.

## KNOWN BUGS/LIMITATIONS

* More testcases are needed.
* All file entries are archived and extracted in binary mode.  No attempt is
  made to normalize text files to the line ending convention of any target
  system.
* Hard links and device files are not currently supported within archives.
* Reading archives from non-seekable IO, such as pipes and sockets, is not
  supported.
* MSDOS permission attributes are not supported.
* Strong encryption is not supported.
* Zip64 is not supported.
* Digital signatures are not supported.

## SYNOPSIS

More examples can be found in the `examples` directory of the source
distribution.

Create a few archives:

```ruby
require 'archive/zip'

# Add a_directory and its contents to example1.zip.
Archive::Zip.archive('example1.zip', 'a_directory')

# Add the contents of a_directory to example2.zip.
Archive::Zip.archive('example2.zip', 'a_directory/.')

# Add a_file and a_directory and its contents to example3.zip.
Archive::Zip.archive('example3.zip', ['a_directory', 'a_file'])

# Add only the files and symlinks contained in a_directory under the path
# a/b/c/a_directory in example4.zip.
Archive::Zip.archive(
  'example4.zip',
  'a_directory',
  :directories => false,
  :path_prefix => 'a/b/c'
)

# Add the contents of a_directory to example5.zip and encrypt Ruby source
# files.
require 'archive/zip/codec/null_encryption'
require 'archive/zip/codec/traditional_encryption'
Archive::Zip.archive(
  'example5.zip',
  'a_directory/.',
  :encryption_codec => lambda do |entry|
    if entry.file? and entry.zip_path =~ /\.rb$/ then
      Archive::Zip::Codec::TraditionalEncryption
    else
      Archive::Zip::Codec::NullEncryption
    end
  end,
  :password => 'seakrit'
)

# Create a new archive which will be written to a pipe.
# Assume $stdout is the write end a pipe.
# (ruby example.rb | cat >example.zip)
Archive::Zip.open($stdout, :w) do |z|
  z.archive('a_directory')
end
```

Now extract those archives:

```ruby
require 'archive/zip'

# Extract example1.zip to a_destination.
Archive::Zip.extract('example1.zip', 'a_destination')

# Extract example2.zip to a_destination, skipping directory entries.
Archive::Zip.extract(
  'example2.zip',
  'a_destination',
  :directories => false
)

# Extract example3.zip to a_destination, skipping symlinks.
Archive::Zip.extract(
  'example3.zip',
  'a_destination',
  :symlinks => false
)

# Extract example4.zip to a_destination, skipping entries for which files
# already exist but are newer or for which files do not exist at all.
Archive::Zip.extract(
  'example4.zip',
  'a_destination',
  :create => false,
  :overwrite => :older
)

# Extract example5.zip to a_destination, decrypting the contents.
Archive::Zip.extract(
  'example5.zip',
  'a_destination',
  :password => 'seakrit'
)
```

## FUTURE WORK ITEMS (in no particular order):

* Add test cases for all classes.
* Add support for using non-seekable IO objects as archive sources.
* Add support for 0x5855 and 0x7855 extra fields.

## REQUIREMENTS

* io-like

## INSTALL

Download the GEM file and install it with:

    $ gem install archive-zip-VERSION.gem

or directly with:

    $ gem install archive-zip

Removal is the same in either case:

    $ gem uninstall archive-zip

## DEVELOPERS

After checking out the source, run:

    $ bundle install
    $ bundle exec rake test yard

This will install all dependencies, run the tests/specs, and generate the
documentation.

## AUTHORS and CONTRIBUTORS

Thanks to all contributors.  Without your help this project would not exist.

* Jeremy Bopp :: jeremy@bopp.net

## CONTRIBUTING

Contributions for bug fixes, documentation, extensions, tests, etc. are
encouraged.

1. Clone the repository.
2. Fix a bug or add a feature.
3. Add tests for the fix or feature.
4. Make a pull request.

### CODING STYLE

The following points are not necessarily set in stone but should rather be used
as a good guideline.  Consistency is the goal of coding style, and changes will
be more easily accepted if they are consistent with the rest of the code.

* **File Encoding**
  * UTF-8
* **Indentation**
  * Two spaces; no tabs
* **Line length**
  * Limit lines to a maximum of 80 characters
* **Comments**
  * Document classes, attributes, methods, and code
* **Method Calls with Arguments**
  * Use `a_method(arg, arg, etc)`; **not** `a_method( arg, arg, etc )`,
    `a_method arg, arg, etc`, or any other variation
* **Method Calls without Arguments**
  * Use `a_method`; avoid parenthesis
* **String Literals**
  * Use single quotes by default
  * Use double quotes when interpolation is necessary
  * Use `%{...}` and similar when embedding the quoting character is cumbersome
* **Blocks**
  * `do ... end` for multi-line blocks and `{ ... }` for single-line blocks
* **Boolean Operators**
  * Use `&&` and `||` for boolean tests; avoid `and` and `or`
* **In General**
  * Try to follow the flow and style of the rest of the code

## LICENSE

```
(The MIT License)

Copyright (c) 2014 Jeremy Bopp

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
