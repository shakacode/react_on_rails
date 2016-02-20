require 'spec_helper'

describe SCSSLint::Linter::BorderZero do
  context 'when a rule is empty' do
    let(:scss) { <<-SCSS }
      p {
      }
    SCSS

    it { should_not report_lint }
  end

  context 'when a property' do
    context 'contains a normal border' do
      let(:scss) { <<-SCSS }
        p {
          border: 1px solid #000;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'has a border of 0' do
      let(:scss) { <<-SCSS }
        p {
          border: 0;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'has a border of none' do
      let(:scss) { <<-SCSS }
        p {
          border: none;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has a border-top of none' do
      let(:scss) { <<-SCSS }
        p {
          border-top: none;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has a border-right of none' do
      let(:scss) { <<-SCSS }
        p {
          border-right: none;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has a border-bottom of none' do
      let(:scss) { <<-SCSS }
        p {
          border-bottom: none;
        }
      SCSS

      it { should report_lint line: 2 }
    end

    context 'has a border-left of none' do
      let(:scss) { <<-SCSS }
        p {
          border-left: none;
        }
      SCSS

      it { should report_lint line: 2 }
    end
  end

  context 'when a convention of `none` is preferred' do
    let(:linter_config) { { 'convention' => 'none' } }

    context 'and the border is `none`' do
      let(:scss) { <<-SCSS }
        p {
          border: none;
        }
      SCSS

      it { should_not report_lint }
    end

    context 'and the border is `0`' do
      let(:scss) { <<-SCSS }
        p {
          border: 0;
        }
      SCSS

      it { should report_lint }
    end

    context 'and the border is a non-zero value' do
      let(:scss) { <<-SCSS }
        p {
          border: 5px;
        }
      SCSS

      it { should_not report_lint }
    end
  end
end
