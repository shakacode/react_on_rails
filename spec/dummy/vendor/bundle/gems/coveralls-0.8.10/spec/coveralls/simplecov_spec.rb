require 'spec_helper'

describe Coveralls::SimpleCov::Formatter do

  before do
    stub_api_post
  end

  def source_fixture(filename)
    File.expand_path( File.join( File.dirname( __FILE__ ), 'fixtures', filename ) )
  end

  let(:result) {

    SimpleCov::Result.new({
      source_fixture( 'sample.rb' )                  => [nil, 1, 1, 1, nil, 0, 1, 1, nil, nil],
      source_fixture( 'app/models/user.rb' )         => [nil, 1, 1, 1, 1, 0, 1, 0, nil, nil],
      source_fixture( 'app/models/robot.rb' )        => [1, 1, 1, 1, nil, nil, 1, 0, nil, nil],
      source_fixture( 'app/models/house.rb' )        => [nil, nil, nil, nil, nil, nil, nil, nil, nil, nil],
      source_fixture( 'app/models/airplane.rb' )     => [0, 0, 0, 0, 0],
      source_fixture( 'app/models/dog.rb' )          => [1, 1, 1, 1, 1],
      source_fixture( 'app/controllers/sample.rb' )  => [nil, 1, 1, 1, nil, 0, 1, 1, nil, nil]
    })
  }

  describe "#format" do
    context "should run" do
      before do
        Coveralls.testing = true
        Coveralls.noisy = false
      end

      it "posts json", :if => RUBY_VERSION >= "1.9" do
        result.files.should_not be_empty
        silence do
          Coveralls::SimpleCov::Formatter.new.format(result).should be_truthy
        end
      end
    end

    context "should not run, noisy" do
      it "only displays result" do
        silence do
          Coveralls::SimpleCov::Formatter.new.display_result(result).should be_truthy
        end
      end
    end

    context "no files" do
      let(:result) { SimpleCov::Result.new({}) }
      it "shows note that no files have been covered" do
        Coveralls.noisy = true
        Coveralls.testing = false

        silence do
          expect do
            Coveralls::SimpleCov::Formatter.new.format(result)
          end.not_to raise_error
        end
      end
    end

    context "with api error" do
      it "rescues" do
        e = RestClient::ResourceNotFound.new double('HTTP Response', :code => '502')
        silence do
          Coveralls::SimpleCov::Formatter.new.display_error(e).should be_falsy
        end
      end
    end

    context "#get_source_files" do
      let(:source_files) { Coveralls::SimpleCov::Formatter.new.get_source_files(result) }
      it "nils the skipped lines" do
        source_file = source_files.first
        source_file[:coverage].should_not eq result.files.first.coverage
        source_file[:coverage].should eq [nil, 1, 1, 1, nil, 0, 1, nil, nil, nil]
      end
    end
  end
end
