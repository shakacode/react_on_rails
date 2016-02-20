unless Object.const_defined? :BindingOfCaller
  $:.unshift File.expand_path '../../lib', __FILE__
  require 'binding_of_caller'
  require 'binding_of_caller/version'
end

class Module
  public :remove_const
end

puts "Testing binding_of_caller version #{BindingOfCaller::VERSION}..."
puts "Ruby version: #{RUBY_VERSION}"

describe BindingOfCaller do
  describe "of_caller" do
    it "should fetch immediate caller's binding when 0 is passed" do
      o = Object.new
      def o.a
        var = 1
        binding.of_caller(0).eval('var')
      end

      o. a.should == 1
    end

    it "should fetch parent of caller's binding when 1 is passed" do
      o = Object.new
      def o.a
        var = 1
        b
      end

      def o.b
        binding.of_caller(1).eval('var')
      end

      o.a.should == 1
    end

    it "should modify locals in parent of caller's binding" do
      o = Object.new
      def o.a
        var = 1
        b
        var
      end

      def o.b
        binding.of_caller(1).eval('var = 20')
      end

      o.a.should == 20
    end

    it "should raise an exception when retrieving an out of band binding" do
      o = Object.new
      def o.a
        binding.of_caller(100)
      end

      lambda { o.a }.should.raise RuntimeError
    end
  end

  describe "callers" do
    before do
      @o = Object.new
    end

    it 'should return the first non-internal binding when using callers.first' do
      def @o.meth
        x = :a_local
        [binding.callers.first, binding.of_caller(0)]
      end

      b1, b2 = @o.meth
      b1.eval("x").should == :a_local
      b2.eval("x").should == :a_local
    end
  end

  describe "frame_count" do
    it 'frame_count should equal callers.count' do
      binding.frame_count.should == binding.callers.count
    end
  end

  describe "frame_descripton" do
    it 'can be called on ordinary binding without raising' do
      lambda { binding.frame_description }.should.not.raise 
    end

    it 'describes a block frame' do
      binding.of_caller(0).frame_description.should =~ /block/
    end

    it 'describes a method frame' do
      o = Object.new
      def o.horsey_malone
        binding.of_caller(0).frame_description.should =~ /horsey_malone/
      end
      o.horsey_malone
    end

    it 'describes a class frame' do
      class HorseyMalone
        binding.of_caller(0).frame_description.should =~ /class/i
      end
      Object.remove_const(:HorseyMalone)
    end
  end

  describe "frame_type" do
    it 'can be called on ordinary binding without raising' do
      lambda { binding.frame_type }.should.not.raise 
    end

    describe "when inside a class definition" do
      before do
        class HorseyMalone
          @binding = binding.of_caller(0)
          def self.binding; @binding; end
        end
        @binding = HorseyMalone.binding
      end

      it 'returns :class' do
        @binding.frame_type.should == :class
      end
    end

    describe "when evaluated" do
      before { @binding = eval("binding.of_caller(0)") }

      it 'returns :eval' do
        @binding.frame_type.should == :eval
      end
    end

    describe "when inside a block" do
      before { @binding = proc { binding.of_caller(0) }.call }

      it 'returns :block' do
        @binding.frame_type.should == :block
      end
    end

    describe "when inside an instance method" do
      before do
        o = Object.new
        def o.a; binding.of_caller(0); end
        @binding = o.a;
      end

      it 'returns :method' do
        @binding.frame_type.should == :method
      end
    end
  end
end

