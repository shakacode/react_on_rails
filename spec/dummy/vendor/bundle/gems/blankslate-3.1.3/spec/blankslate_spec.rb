require 'blankslate'
require 'rspec'

describe BlankSlate do

  RSPEC_MOCK_METHODS = [
    "as_null_object",
    "null_object?",
    "received_message?",
    "should",
    "should_not",
    "should_not_receive",
    "should_receive",
    "stub",
    "stub_chain",
    "unstub"
  ]

  let(:blank_slate) { BlankSlate.new }

  def call(obj, meth, *args)
    BlankSlate.find_hidden_method(meth).bind(obj).call(*args)
  end

  describe "cleanliness" do
    it "should not have many methods" do
      methods = BlankSlate.instance_methods.map(&:to_s)
      (methods - RSPEC_MOCK_METHODS.sort).should =~ [
        "__id__", "__send__", "instance_eval", "object_id"
      ]
    end
  end

  context "when methods are added to Object" do
    after(:each) {
      class Object
        undef :foo
      end
    }

    it "should still be blank" do
      class Object
        def foo
        end
      end
      Object.new.foo

      lambda {
        BlankSlate.new.foo
      }.should raise_error(NoMethodError)
    end

  end
end
