require 'helper'

Pry.config.output = StringIO.new

describe PryStackExplorer::FrameManager do

  before do
    @pry_instance = Pry.new
    @bindings = [binding, binding, binding, binding]
    @bindings.each_with_index { |v, i| v.eval("x = #{i}") }
    @pry_instance.binding_stack.push @bindings.last
    @frame_manager = PE::FrameManager.new(@bindings, @pry_instance)
  end

  describe "creation" do
    it "should make bindings accessible via 'bindings' method" do
      @frame_manager.bindings.should == @bindings
    end

    it "should set binding_index to 0" do
      @frame_manager.binding_index.should == 0
    end

    it "should set current_frame to first frame" do
      @frame_manager.current_frame.should == @bindings.first
    end
  end

  describe "FrameManager#change_frame_to" do
    it 'should change the frame to the given one' do
      @frame_manager.change_frame_to(1)

      @frame_manager.binding_index.should == 1
      @frame_manager.current_frame.should == @bindings[1]
      @pry_instance.binding_stack.last.should == @frame_manager.current_frame
    end

    it 'should accept negative indices when specifying frame' do
      @frame_manager.change_frame_to(-1)

      # negative index is converted to a positive one inside change_frame_to
      @frame_manager.binding_index.should == @bindings.size - 1

      @frame_manager.current_frame.should == @bindings[-1]
      @pry_instance.binding_stack.last.should == @frame_manager.current_frame
    end
  end

  describe "FrameManager#refresh_frame" do
    it 'should change the Pry frame to the active one in the FrameManager' do
      @frame_manager.binding_index = 2
      @frame_manager.refresh_frame

      @pry_instance.binding_stack.last.should == @frame_manager.current_frame
    end
  end

  describe "FrameManager is Enumerable" do
    it 'should perform an Enumerable#map on the frames' do
      @frame_manager.map { |v| v.eval("x") }.should == (0..(@bindings.size - 1)).to_a
    end
  end

end

