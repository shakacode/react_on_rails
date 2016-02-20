# News and Notifications by Version

This file lists noteworthy changes which may affect users of this project.  More
detailed information is available in the rest of the documentation.

**NOTE:** Date stamps in the following entries are in YYYY/MM/DD format.


## v0.7.0 (2014/08/18)

### Fixes

* Avoid corrupting the archive when storing entries that have multibyte names.

### Notes

* Ruby 1.8.6 support has been dropped.
  * This may come back if demand warrants it.
* Switched to the MIT license.
* Now using minitest instead of mspec for tests.

## v0.6.0 (2013/03/24)

### Fixes

* Only define Zlib constants when they are not already defined.
  * Fixes constant redefinition warnings under MRI 2.0.0-p0.
* Force Zlib::ZWriter and Zlib::ZReader #checksum methods to return nil for raw
  streams.
  * The behavior of the underlying Zlib::Deflate and Zlib::Inflate classes'
    #adler methods appear inconsistent for raw streams and really aren't
    necessary in this case anyway.

### Notes

* Broke backward compatibility with the behavior of Zlib::ZWriter#checksum and
  Zlib::ZReader#checksum when working with raw streams.
  * This should not affect direct users of Archive::Zip because the checksum
    methods of those classes are never used.

## v0.5.0 (2012/03/01)

### Fixes

* Avoid timezone discrepancies in encryption tests.
* Moved the DOSTime class to the Archive namespace (Chris Schneider).

### Notes

* Broke backward compatibility of the DOSTime class.

## v0.4.0 (2011/08/29)

### Features

* Added Ruby 1.9 support.
* Simplified arguments for Archive::Zip.new.
  * Archives cannot be directly opened for modification.
  * Archive::Zip.archive can still emulate modifying an archive in place.
* Added a bunch of tests (many more still needed).
* Updated and simplified rake tasks.
* Created a standalone gemspec file.

### Fixes

* Fixed a potential data loss bug in Zlib::ZReader.
* Archives larger than the maximum Fixnum for the platform don't falsely raise a
  "non-integer windows position given" error.

### Notes

* Broke backward compatibility for Archive::Zip.new.
  * Wrapper class methods continue to work as before.
* Broke backward compatibility for Archive::Zip::ExtraField.
  * Allows separate handling of extra fields in central and local records.

## v0.3.0 (2009/01/23)

* Made a significant performance improvement for the extraction of compressed
  entries for performance on par with InfoZIP's unzip.  Parsing archives with
  many entries is still a bit subpar however.


## v0.2.0 (2008/08/06)

* Traditional (weak) encryption is now supported.
* Adding new encryption methods should be easier now.
* Fixed a bug where the compression codec for an entry loaded from an archive
  was not being recorded.
* The _compression_codec_ attribute for Entry instances is now used instead of
  the _codec_ attribute to access the compression codec of the entry.


## v0.1.1 (2008/07/11)

* Archive files are now closed when the Archive::Zip object is closed even when
  no changes were made to the archive, a problem on Windows if you want to
  delete the archive after extracting it within the same script.


## v0.1.0 (2008/07/10)

* Initial release.
* Archive creation and extraction is supported with only a few lines of code.
  (See README)
* Archives can be updated "in place" or dumped out to other files or pipes.
* Files, symlinks, and directories are supported within archives.
* Unix permission/mode bits are supported.
* Unix user and group ownerships are supported.
* Unix last accessed and last modified times are supported.
* Entry extension (AKA extra field) implementations can be added on the fly.
* Unknown entry extension types are preserved during archive processing.
* Deflate and Store compression codecs are supported out of the box.
* More compression codecs can be added on the fly.
