require File.expand_path('../../lib/pry-rescue.rb', __FILE__)
require 'uri'

describe "PryRescue.load" do
  if defined?(PryStackExplorer)
    it "should open at the correct point" do
      PryRescue.should_receive(:pry).once{ |opts|
        opts[:call_stack].first.eval("__FILE__").should end_with('spec/fixtures/simple.rb')
      }
      lambda{
        PryRescue.load("spec/fixtures/simple.rb")
      }.should raise_error(/simple-exception/)
    end

    it "should open above the standard library" do
      PryRescue.should_receive(:pry).once do |opts|
        opts[:call_stack][opts[:initial_frame]].eval("__FILE__").should end_with('spec/fixtures/uri.rb')
      end
      lambda{
        PryRescue.load("spec/fixtures/uri.rb")
      }.should raise_error(URI::InvalidURIError)
    end

    it "should keep the standard library on the binding stack" do
      PryRescue.should_receive(:pry).once do |opts|
        opts[:call_stack].first.eval("__FILE__").should start_with(RbConfig::CONFIG['libdir'])
      end
      lambda{
        PryRescue.load("spec/fixtures/uri.rb")
      }.should raise_error(URI::InvalidURIError)
    end

    it "should open above gems" do
      PryRescue.should_receive(:pry).once do |opts|
        opts[:call_stack][opts[:initial_frame]].eval("__FILE__").should end_with('spec/fixtures/coderay.rb')
      end
      lambda{
        PryRescue.load("spec/fixtures/coderay.rb")
      }.should raise_error(ArgumentError)
    end

    it "should open above gems" do
      PryRescue.should_receive(:pry).once do |opts|
        coderay_path = Gem::Specification.respond_to?(:detect) ?
                         Gem::Specification.detect{|x| x.name == 'coderay' }.full_gem_path :
                         Gem.all_load_paths.grep(/coderay/).last

        opts[:call_stack].first.eval("__FILE__").should start_with(coderay_path)
      end
      lambda{
        PryRescue.load("spec/fixtures/coderay.rb")
      }.should raise_error(ArgumentError)
    end

    it "should skip pwd, even if it is a gem (but not vendor stuff)" do
      Gem::Specification.stub :any? do true end
      PryRescue.send(:user_path?, Dir.pwd + '/asdf.rb').should be_true
      PryRescue.send(:user_path?, Dir.pwd + '/vendor/asdf.rb').should be_false
    end

    it "should filter out duplicate stack frames" do
      PryRescue.should_receive(:pry).once do |opts|
        opts[:call_stack][0].eval("__LINE__").should == 4
        opts[:call_stack][1].eval("__LINE__").should == 12
      end
      lambda{
        PryRescue.load("spec/fixtures/super.rb")
      }.should raise_error(/super-exception/)
    end

    it "should calculate correct initial frame even when duplicates are present" do
      PryRescue.should_receive(:pry).once do |opts|
        opts[:call_stack][0].eval("__FILE__").should end_with('fake.rb')
        opts[:call_stack][opts[:initial_frame]].eval("__FILE__").should end_with('spec/fixtures/initial.rb')
      end
      lambda{
        PryRescue.load("spec/fixtures/initial.rb")
      }.should raise_error(/no :baz please/)
    end

    it "should skip over reraises from within gems" do
      PryRescue.should_receive(:pry).once do |opts|
        opts[:call_stack][0].eval("__FILE__").should end_with('spec/fixtures/reraise.rb')
      end
      lambda{
        PryRescue.load("spec/fixtures/reraise.rb")
      }.should raise_error(/reraise-exception/)
    end

    it "should not skip over independent raises within gems" do
      PryRescue.should_receive(:pry).once do |opts|
        opts[:call_stack][0].eval("__FILE__").should end_with('fake.rb')
      end
      lambda{
        PryRescue.load("spec/fixtures/raiseother.rb")
      }.should raise_error(/raiseother_exception/)
    end

    it "should output a warning if the exception was not raised" do
      PryRescue.should_not_receive(:enter_exception_context)
      Pry.should_receive(:warn).once
      Pry.rescued(RuntimeError.new("foo"))
    end
  else
    it "should open at the correct point" do
      Pry.should_receive(:start).once{ |binding, h|
        binding.eval("__FILE__").should end_with('spec/fixtures/simple.rb')
      }
      lambda{
        PryRescue.load("spec/fixtures/simple.rb")
      }.should raise_error(/simple-exception/)
    end
  end
end
