require 'byebug/setting'

module Byebug
  #
  # Setting to enable/disable linetracing.
  #
  class LinetraceSetting < Setting
    def banner
      'Enable line execution tracing'
    end

    def value=(v)
      Byebug.tracing = v
    end

    def value
      Byebug.tracing?
    end
  end
end
