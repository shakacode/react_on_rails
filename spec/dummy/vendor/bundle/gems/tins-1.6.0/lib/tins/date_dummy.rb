require 'date'

module Tins
  module DateDummy
    def self.included(modul)
      class << modul
        alias really_today today

        remove_method :today rescue nil

        def dummy=(value)
          if value.respond_to?(:to_str)
            value = Date.parse(value.to_str)
          elsif value.respond_to?(:to_date)
            value = value.to_date
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

        def today
          if dummy
            dummy.dup
          elsif caller.first =~ /`today`/
            really_today
          else
            really_today
          end
        end

        end
      super
    end
  end
end

require 'tins/alias'

