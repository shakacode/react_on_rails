module Tins
  module ModuleGroup
    def self.[](*modules)
      modul = Module.new
      modules.each do |m|
        m.module_eval { include modul }
      end
      modul
    end
  end
end

require 'tins/alias'
