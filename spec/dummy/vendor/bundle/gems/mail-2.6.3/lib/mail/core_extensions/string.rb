# encoding: utf-8
class String #:nodoc:

  CRLF = "\r\n"
  LF   = "\n"

  if RUBY_VERSION >= '1.9'
    # This 1.9 only regex can save a reasonable amount of time (~20%)
    # by not matching "\r\n" so the string is returned unchanged in
    # the common case.
    CRLF_REGEX = Regexp.new("(?<!\r)\n|\r(?!\n)")
  else
    CRLF_REGEX = /\n|\r\n|\r/
  end

  def to_crlf
    to_str.gsub(CRLF_REGEX, CRLF)
  end

  def to_lf
    to_str.gsub(/\r\n|\r/, LF)
  end

  unless String.instance_methods(false).map {|m| m.to_sym}.include?(:blank?)
    def blank?
      self !~ /\S/
    end
  end

  unless method_defined?(:ascii_only?)
    # Backport from Ruby 1.9 checks for non-us-ascii characters.
    def ascii_only?
      self !~ MATCH_NON_US_ASCII
    end

    MATCH_NON_US_ASCII = /[^\x00-\x7f]/
  end

  def not_ascii_only?
    !ascii_only?
  end

  unless method_defined?(:bytesize)
    alias :bytesize :length
  end
end
