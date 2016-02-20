###
# In our specs, I want to make sure time gets mocked so I can accurately test
# times displayed to the user.
#
class PBTimeTester
  def self.now
    ::Time.now
  end
end

class ProgressBar
class Time
  class << self
    alias_method :old_now, :now

    def now(time = ::PBTimeTester)
      old_now(time)
    end
  end
end
end
