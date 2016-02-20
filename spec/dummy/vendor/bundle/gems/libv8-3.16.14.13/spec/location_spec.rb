require 'spec_helper'

describe "libv8 locations" do
  before do
    @context = double(:CompilationContext)
  end

  describe "the system location" do
    before do
      @location = Libv8::Location::System.new
      @context.stub(:dir_config)
    end

    describe "configuring a compliation context with it" do
      before do
        @context.stub(:find_header) {true}
        @context.stub(:have_library) {true}
        @location.configure @context
      end

      it "adds the include path to the front of the include flags" do
        @context.should have_received(:dir_config).with('v8').at_least(:once)
        @context.should have_received(:find_header).with('v8.h').at_least(:once)
        @context.should have_received(:have_library).with('v8').at_least(:once)
      end
    end

    describe "when the v8 library cannot be found" do
      before do
        @context.stub(:find_header) {true}
        @context.stub(:have_library) {false}
      end

      it "raises a NotFoundError" do
        expect {@location.configure @context}.to raise_error Libv8::Location::System::NotFoundError
      end
    end

    describe "when the v8.h header cannot be found" do
      before do
        @context.stub(:find_header) {false}
        @context.stub(:have_library) {true}
      end

      it "raises a NotFoundError" do
        expect {@location.configure @context}.to raise_error Libv8::Location::System::NotFoundError
      end
    end
  end

  describe "the vendor location" do
    before do
      @location = Libv8::Location::Vendor.new
      @context.stub(:incflags) {@incflags ||= "-I/usr/include -I/usr/local/include"}
      @context.stub(:ldflags) {@ldflags ||= "-lobjc -lpthread"}

      Libv8::Paths.stub(:vendored_source_path) {"/foo bar/v8"}
      Libv8::Arch.stub(:libv8_arch) {'x64'}
      @location.configure @context
    end

    it "prepends its own incflags before any pre-existing ones" do
      @context.incflags.should eql "-I/foo\\ bar/v8/include -I/usr/include -I/usr/local/include"
    end

    it "prepends the locations of any libv8 objects on the the ldflags" do
      @context.ldflags.should eql "/foo\\ bar/v8/out/x64.release/obj.target/tools/gyp/libv8_base.a /foo\\ bar/v8/out/x64.release/obj.target/tools/gyp/libv8_snapshot.a -lobjc -lpthread"
    end
  end
end
