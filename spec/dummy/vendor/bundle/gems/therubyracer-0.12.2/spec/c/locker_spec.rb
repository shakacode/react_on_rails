require 'spec_helper'

describe V8::C::Locker do
  include ExplicitScoper

  it "can lock and unlock the VM" do
    V8::C::Locker::IsLocked().should be_false
    V8::C::Locker() do
      V8::C::Locker::IsLocked().should be_true
      V8::C::Unlocker() do
        V8::C::Locker::IsLocked().should be_false
      end
    end
    V8::C::Locker::IsLocked().should be_false
  end

  it "properly unlocks if an exception is thrown inside a lock block" do
    begin
      V8::C::Locker() do
        raise "boom!"
      end
    rescue
      V8::C::Locker::IsLocked().should be_false
    end
  end

  it "properly re-locks if an exception is thrown inside an un-lock block" do
    V8::C::Locker() do
      begin
        V8::C::Unlocker() do
          raise "boom!"
        end
      rescue
        V8::C::Locker::IsLocked().should be_true
      end
    end
  end
end