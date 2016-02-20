require 'tins/secure_write'

module Tins
  module Write
    def self.extended(modul)
      modul.extend SecureWrite
      if modul.respond_to?(:write)
        $DEBUG and warn "Skipping inclusion of Tins::Write#write method, include Tins::Write::SecureWrite#secure_write instead"
      else
        class << modul; self; end.instance_eval do
          alias_method :write, :secure_write
        end
      end
      super
    end
  end
end

require 'tins/alias'
