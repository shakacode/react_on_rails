require 'spec_helper'

describe SCSSLint::Reporter::DefaultReporter do
  let(:logger) { SCSSLint::Logger.new($stdout) }
  subject { SCSSLint::Reporter::DefaultReporter.new(lints, [], logger) }

  describe '#report_lints' do
    context 'when there are no lints' do
      let(:lints) { [] }

      it 'returns nil' do
        subject.report_lints.should be_nil
      end
    end

    context 'when there are lints' do
      let(:filenames)    { ['some-filename.scss', 'other-filename.scss'] }
      let(:lines)        { [502, 724] }
      let(:descriptions) { ['Description of lint 1', 'Description of lint 2'] }
      let(:severities)   { [:warning] * 2 }
      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          location = SCSSLint::Location.new(lines[index])
          SCSSLint::Lint.new(nil, filename, location, descriptions[index],
                             severities[index])
        end
      end

      it 'prints each lint on its own line' do
        subject.report_lints.count("\n").should == 2
      end

      it 'prints a trailing newline' do
        subject.report_lints[-1].should == "\n"
      end

      it 'prints the filename for each lint' do
        filenames.each do |filename|
          subject.report_lints.scan(filename).count.should == 1
        end
      end

      it 'prints the line number for each lint' do
        lines.each do |line|
          subject.report_lints.scan(line.to_s).count.should == 1
        end
      end

      it 'prints the description for each lint' do
        descriptions.each do |description|
          subject.report_lints.scan(description).count.should == 1
        end
      end

      context 'when lints are warnings' do
        it 'prints the warning severity code on each line' do
          subject.report_lints.split("\n").each do |line|
            line.scan(/\[W\]/).count.should == 1
          end
        end
      end

      context 'when lints are errors' do
        let(:severities) { [:error] * 2 }

        it 'prints the error severity code on each line' do
          subject.report_lints.split("\n").each do |line|
            line.scan(/\[E\]/).count.should == 1
          end
        end
      end
    end
  end
end
