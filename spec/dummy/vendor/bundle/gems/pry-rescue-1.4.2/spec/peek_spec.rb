ENV['NO_PEEK_STARTUP_MESSAGE'] = 'true'

describe "PryRescue.peek!" do
  it "should open a pry in the binding of caller" do
    Pry.config.input = StringIO.new("foo = 6\nexit\n")
    Pry.config.output = StringIO.new
    foo = 5

    lambda do
      PryRescue.peek!
    end.should change{ foo }.from(5).to(6)
  end

  # this will fail, or not?
  it 'should include the entire call stack' do
    Pry.config.input = StringIO.new("up\nfoo = 6\nexit\n")
    Pry.config.output = StringIO.new

    def example_method
      PryRescue.peek!
    end

    foo = 5

    lambda do
      PryRescue.peek!
    end.should change{ foo }.from(5).to(6)
  end
end
