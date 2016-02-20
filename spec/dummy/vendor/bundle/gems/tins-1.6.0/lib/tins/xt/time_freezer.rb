require 'tins/xt/time_dummy'
require 'tins/xt/date_time_dummy'
require 'tins/xt/date_dummy'

module Tins::TimeFreezer
  def self.freeze(time)
    Time.dummy(time) do
      DateTime.dummy(time) do
        Date.dummy(time) do
          yield
        end
      end
    end
  end
end
