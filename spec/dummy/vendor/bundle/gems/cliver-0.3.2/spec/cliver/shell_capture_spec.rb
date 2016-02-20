# encoding: utf-8
require 'cliver'

describe Cliver::ShellCapture do
  let(:test_command) { 'test command' }
  subject { Cliver::ShellCapture.new(test_command) }

  context 'a command that exists' do
    let(:intended_stdout) { StringIO.new('1.1.1').tap(&:rewind) }
    let(:intended_stderr) { StringIO.new('foo baar 1').tap(&:rewind) }
    let(:intended_stdin)  { StringIO.new('').tap(&:rewind) }

    ['test command', %w(test command)].each do |input|
      context "with #{input.class.name} input" do
        let(:test_command) { input }

        before(:each) do
          Open3.should_receive(:popen3) do |*args|
            args.size.should eq 1
            args.first.should == 'test command'
          end.and_yield(intended_stdin, intended_stdout, intended_stderr)
        end

        its(:stdout) { should eq '1.1.1' }
        its(:stderr) { should eq 'foo baar 1' }
        its(:command_found) { should be_true }
      end
    end
  end

  context 'looking for a command that does not exist' do
    before(:each) do
      Open3.should_receive(:popen3) do |command|
        command.should eq test_command
        raise Errno::ENOENT.new("No such file or directory - #{test_command}")
      end
    end
    its(:stdout) { should eq '' }
    its(:stderr) { should eq '' }
    its(:command_found) { should be_false }
  end
end
