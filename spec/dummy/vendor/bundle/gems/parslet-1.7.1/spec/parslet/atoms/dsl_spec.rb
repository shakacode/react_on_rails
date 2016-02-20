require 'spec_helper'

describe Parslet::Atoms::DSL do
  describe "deprecated methods" do
    let(:parslet) { Parslet.str('foo') }
    describe "<- #absnt?" do
      slet(:absnt) { parslet.absnt? }
      it '#bound_parslet' do
        absnt.bound_parslet.should == parslet
      end
      it 'should be a negative lookahead' do
        absnt.positive.should == false
      end
    end
    describe "<- #prsnt?" do
      slet(:prsnt) { parslet.prsnt? }
      it '#bound_parslet' do
        prsnt.bound_parslet.should == parslet
      end
      it 'should be a positive lookahead' do
        prsnt.positive.should == true
      end
    end
  end
end