# encoding: UTF-8

module Archive; class Zip;
  # Archive::Zip::Error is the base class of all archive-related errors raised
  # by the Archive::Zip library.
  class Error < StandardError; end

  # Archive::Zip::EntryError is raised when there is an error while processing
  # ZIP archive entries.
  class EntryError < Error; end

  # Archive::Zip::ExtraFieldError is raised when there is an error while
  # processing an extra field in a ZIP archive entry.
  class ExtraFieldError < Error; end

  # Archive::Zip::IOError is raised in various places where either an IOError is
  # raised or an operation on an Archive::Zip object is disallowed because of
  # the state of the object.
  class IOError < Error; end

  # Archive::Zip::UnzipError is raised when attempting to extract an archive
  # fails but no more exact error class exists for reporting the error.
  class UnzipError < Error; end
end; end
