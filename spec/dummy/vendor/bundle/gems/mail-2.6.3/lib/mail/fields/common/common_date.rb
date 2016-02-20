# encoding: utf-8
module Mail
  module CommonDate # :nodoc:
    # Returns a date time object of the parsed date
    def date_time
      ::DateTime.parse("#{element.date_string} #{element.time_string}")
    end

    def default
      date_time
    end
    
    def parse(val = value)
      unless val.blank?
        @element = Mail::DateTimeElement.new(val)
      else
        nil
      end
    end

    private
    
    def do_encode(field_name)
      "#{field_name}: #{value}\r\n"
    end
    
    def do_decode
      "#{value}"
    end

    def element
      @element ||= Mail::DateTimeElement.new(value)
    end
  end
end
