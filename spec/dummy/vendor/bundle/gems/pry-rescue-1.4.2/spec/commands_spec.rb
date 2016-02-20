require './spec/spec_helper'

describe "pry-rescue commands" do
  describe "try-again" do
    it "should throw try_again" do
      PryRescue.should_receive(:in_exception_context?).and_return{ true }

      lambda{
        Pry.new.process_command "try-again", '', TOPLEVEL_BINDING
      }.should throw_symbol :try_again
    end

    it "should raise a CommandError if not in Pry::rescue" do
      PryRescue.should_receive(:in_exception_context?).and_return{ false }

      lambda{
        Pry.new.process_command "try-again", '', TOPLEVEL_BINDING
      }.should raise_error Pry::CommandError
    end
  end

  describe "cd-cause" do
    it "should enter the context of an explicit exception" do
      begin
        b1 = binding
        raise "original"
      rescue => e1
        b2 = binding
      end

      Pry.should_receive(:rescued).once.with{ |raised|
        raised.should == e1
      }

      Pry.new.process_command 'cd-cause e1', '', binding
    end

    it "should enter the context of _ex_ if no exception is given" do
      b2 = nil
      _ex_ = nil
      Pry::rescue do
        begin
          b1 = binding
          raise "original"
        rescue => _ex_
          b2 = binding
        end
      end

      Pry.should_receive(:rescued).once.with{ |raised|
        raised.should == _ex_
      }

      Pry.new.process_command 'cd-cause', '', b2
    end
  end

  describe "cd-cause" do
    it "should enter the next exception's context" do
      _ex_ = nil
      e1 = nil
      Pry::rescue do
        begin
          begin
            b1 = binding
            raise "original"
          rescue => e1
            b2 = binding
            raise # similar to dubious re-raises you'll find in the wild
          end
        rescue => e2
          _ex_ = e2
        end
      end

      PryRescue.should_receive(:enter_exception_context).once.with(e1)

      Pry.new.process_command 'cd-cause', '', binding
    end

    it "should raise a CommandError if no previous commands" do
      begin
        b1 = binding
        raise "original"
      rescue => e1
        # Hacks due to us not really entering a pry session here
        _rescued_ = e1
        _ex_ = e1
      end

      lambda{
        Pry.new.process_command 'cd-cause', '', binding
      }.should raise_error Pry::CommandError, /No previous exception/
    end

    it "should raise a CommandError on a re-raise" do
      _ex_ = nil
      Pry::rescue do
        begin
          begin
            raise "oops"
          rescue => e
            raise e
          end
        rescue => _ex_
        end
      end
      _rescued_ = _ex_

      lambda{
        Pry.new.process_command 'cd-cause', '', binding
      }.should raise_error Pry::CommandError, /No previous exception/
    end

    it "should raise a CommandError if not in Pry::rescue" do
      lambda{
        Pry.new.process_command 'cd-cause', '', binding
      }.should raise_error Pry::CommandError, /No previous exception/
    end
  end
end
