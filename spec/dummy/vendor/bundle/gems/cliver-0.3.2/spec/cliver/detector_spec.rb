# encoding: utf-8
require 'cliver'

describe Cliver::Detector do
  let(:detector) { Cliver::Detector.new(*args) }
  let(:defaults) do
    {
      :version_pattern => Cliver::Detector::DEFAULT_VERSION_PATTERN,
      :command_arg =>     Cliver::Detector::DEFAULT_COMMAND_ARG,
    }
  end
  let(:args) { [] }
  subject { detector }

  it { should respond_to :to_proc }

  its(:command_arg) { should eq defaults[:command_arg] }
  its(:version_pattern) { should eq defaults[:version_pattern] }

  context 'with one string argument' do
    let(:version_arg) { '--release-version' }
    let(:args) { [version_arg] }

    its(:command_arg) { should eq [version_arg] }
    its(:version_pattern) { should eq defaults[:version_pattern] }
  end

  context 'with one regexp argument' do
    let(:regexp_arg) { /.*/ }
    let(:args) { [regexp_arg] }

    its(:command_arg) { should eq defaults[:command_arg] }
    its(:version_pattern) { should eq regexp_arg }
  end

  context 'with both arguments' do
    let(:version_arg) { '--release-version' }
    let(:regexp_arg) { /.*/ }
    let(:args) { [version_arg, regexp_arg] }

    its(:command_arg) { should eq [version_arg] }
    its(:version_pattern) { should eq regexp_arg }
  end

  context 'detecting a command' do
    before(:each) do
      Cliver::ShellCapture.stub(:new => capture)
    end

    context 'that reports version on stdout' do
      let(:capture) { double('capture', :stdout => '1.1',
                                        :stderr => 'Warning: There is a monkey 1.2 metres left of you.',
                                        :command_found => true) }

      it 'should prefer the stdout output' do
        expect(detector.detect_version('foo')).to eq('1.1')
      end
    end

    context 'that reports version on stderr' do
      let(:capture) { double('capture', :stdout => '',
                                        :stderr => 'Version: 1.666',
                                        :command_found => true) }

      it 'should prefer the stderr output' do
        expect(detector.detect_version('foo')).to eq('1.666')
      end
    end

    context 'that does not exist' do
      let(:capture) { Cliver::ShellCapture.new('acommandnosystemshouldhave123') }

      it 'should raise an exception' do
        expect { detector.detect_version('foo') }.to raise_error(Cliver::Dependency::NotFound)
      end
    end
  end
end
