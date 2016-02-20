require 'capybara-screenshot'
require 'capybara/dsl'

describe Capybara do
  it 'adds screen shot methods to the Capybara module' do
    expect(::Capybara).to respond_to(:screenshot_and_save_page)
    expect(::Capybara).to respond_to(:screenshot_and_open_image)
  end

  context 'request type example', :type => :request do
    it 'has access to screen shot instance methods' do
      expect(subject).to respond_to(:screenshot_and_save_page)
      expect(subject).to respond_to(:screenshot_and_open_image)
    end
  end

  describe 'using_session' do
    include Capybara::DSL

    it 'saves the name of the final session' do
      expect(Capybara::Screenshot).to receive(:final_session_name=).with(:different_session)
      expect {
        using_session :different_session do
          expect(0).to eq 1
        end
      }.to raise_exception ::RSpec::Expectations::ExpectationNotMetError
    end
  end
end

describe 'final_session_name' do
  subject { Capybara::Screenshot.clone }

  describe 'when the final session name has been set' do
    before do
      subject.final_session_name = 'my-failing-session'
    end

    it 'returns the name' do
      expect(subject.final_session_name).to eq 'my-failing-session'
    end
  end

  describe 'when the final session name has not been set' do
    it 'returns the current session name' do
      allow(Capybara).to receive(:session_name).and_return('my-current-session')
      expect(subject.final_session_name).to eq 'my-current-session'
    end
  end
end
