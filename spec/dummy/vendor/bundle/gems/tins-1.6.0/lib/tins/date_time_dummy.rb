require 'date'

module Tins
  module DateTimeDummy
    def self.included(modul)
      class << modul
        alias really_now now

        remove_method :now rescue nil

        def dummy=(value)
          if value.respond_to?(:to_str)
            value = DateTime.parse(value.to_str)
          elsif value.respond_to?(:to_datetime)
            value = value.to_datetime
          end
          @dummy = value
        end

        def dummy(value = nil)
          if value.nil?
            @dummy
          else
            begin
              old_dummy = @dummy
              self.dummy = value
              yield
            ensure
              self.dummy = old_dummy
            end
          end
        end

        def now
          if dummy
            dummy.dup
          elsif caller.first =~ /`now`/
            really_now
          else
            really_now
          end
        end
      end
      super
    end
  end
end

require 'tins/alias'
