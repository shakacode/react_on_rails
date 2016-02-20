require File.expand_path('../../lib/pry-rescue.rb', __FILE__)

describe 'Pry.rescue' do
  it 'should call PryRescue.enter_exception_context' do
    lambda{
      PryRescue.should_receive(:enter_exception_context).once
      Pry::rescue{ raise "foobar" }
    }.should raise_error(/foobar/)
  end

  it "should retry on try-again" do
    @called = 0
    PryRescue.should_receive(:enter_exception_context).once{ throw :try_again }
    Pry::rescue do
      @called += 1
      raise "foobar" if @called == 1
    end
    @called.should == 2
  end

  it "should try-again from innermost block" do
    @outer = @inner = 0
    PryRescue.should_receive(:enter_exception_context).once{ throw :try_again }
    Pry::rescue do
      @outer += 1
      Pry::rescue do
        @inner += 1
        raise "oops" if @inner == 1
      end
    end

    @outer.should == 1
    @inner.should == 2
  end

  it "should enter the first occurence of an exception that is re-raised" do
    PryRescue.should_receive(:enter_exception_context).once{ |raised| raised.size.should == 1 }
    lambda do
      Pry::rescue do
        begin
          raise "first_occurance"
        rescue => e
          raise
        end
      end
    end.should raise_error(/first_occurance/)
  end

  it "should not catch SystemExit" do
    PryRescue.should_not_receive(:enter_exception_context)

    lambda do
      Pry::rescue do
        exit
      end
    end.should raise_error SystemExit
  end

  it 'should not catch Ctrl+C' do
    PryRescue.should_not_receive(:enter_exception_context)
    lambda do
      Pry::rescue do
        raise Interrupt, "ctrl+c (fake)"
      end
    end.should raise_error Interrupt
  end
end

describe "Pry.rescued" do

  it "should raise an error if used outwith Pry::rescue" do
    begin
      raise "foo"
    rescue => e
      Pry.should_receive(:warn)
      Pry.rescued(e)
    end
  end

  it "should raise an error if used on an exception not raised" do
    Pry::rescue do
      Pry.should_receive(:warn) do |message|
        message.should =~ /^WARNING: Tried to inspect exception outside of Pry::rescue/
      end
      Pry.rescued(RuntimeError.new("foo").exception)
    end
  end

  it "should call Pry.enter_exception_context" do
    Pry::rescue do
      begin
        raise "foo"
      rescue => e
        PryRescue.should_receive(:enter_exception_context).once
        Pry::rescued(e)
      end
    end
  end
end

