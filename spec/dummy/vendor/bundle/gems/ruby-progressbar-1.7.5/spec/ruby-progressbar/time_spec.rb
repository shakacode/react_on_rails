require 'spec_helper'

class TimeMockedWithTimecop
  def self.now; end
  def self.now_without_mock_time; end
end

class TimeMockedWithDelorean
  def self.now; end
  def self.now_without_delorean; end
end

class UnmockedTime
  def self.now; end
end

class     ProgressBar
describe  Time do
  it 'when Time is being mocked by Timecop retrieves the unmocked Timecop time' do
    allow(TimeMockedWithTimecop).to receive(:now_without_mock_time).once

    Time.now(TimeMockedWithTimecop)
  end

  it 'when Time is being mocked by Delorean retrieves the unmocked Delorean time' do
    allow(TimeMockedWithDelorean).to receive(:now_without_delorean).once

    Time.now(TimeMockedWithDelorean)
  end

  it 'when Time is not being mocked will return the actual time' do
    allow(UnmockedTime).to receive(:now).once

    Time.now(UnmockedTime)
  end
end
end
