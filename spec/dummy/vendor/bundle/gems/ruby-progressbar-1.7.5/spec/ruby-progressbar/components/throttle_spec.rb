require 'rspectacular'
require 'ruby-progressbar/progress'

class     ProgressBar
describe  Throttle do
  let(:timer) { ProgressBar::Timer.new(:time => ::Time) }

  it 'yields the first time if the throttle rate is given and the timer is not started' do
    throttle = ProgressBar::Throttle.new(:throttle_rate  => 10,
                                         :throttle_timer => timer)

    yielded = false

    throttle.choke do
      yielded = true
    end

    expect(yielded).to be_a TrueClass
  end

  it 'does not yield after the initial yield if the period has not passed yet' do
    throttle = ProgressBar::Throttle.new(:throttle_rate  => 10,
                                         :throttle_timer => timer)
    timer.start

    throttle.choke {}

    yielded = false

    (1..9).each do
      Timecop.freeze(1)

      throttle.choke do
        yielded = true
      end
    end

    Timecop.return

    expect(yielded).to be_a FalseClass
  end

  it 'always yields if forced to, even after the initial yield or if the period ' \
     'has not passed' do

    throttle = ProgressBar::Throttle.new(:throttle_rate  => 10,
                                         :throttle_timer => timer)
    timer.start

    throttle.choke {}

    yielded = 0

    (1..25).each do
      Timecop.freeze(1)

      throttle.choke(:force_update_if => true) do
        yielded += 1
      end
    end

    Timecop.return

    expect(yielded).to eql 25
  end

  it 'yields if the period has passed, even after the initial yield' do
    throttle = ProgressBar::Throttle.new(:throttle_rate  => 10,
                                         :throttle_timer => timer)
    timer.start

    throttle.choke {}

    yielded = false

    Timecop.freeze(11)

    throttle.choke do
      yielded = true
    end

    Timecop.return

    expect(yielded).to eql true
  end

  it 'does not yield after a previous yield if the period has not passed yet' do
    throttle = ProgressBar::Throttle.new(:throttle_rate  => 10,
                                         :throttle_timer => timer)

    Timecop.freeze(0)

    timer.start

    Timecop.freeze(15)

    throttle.choke {}

    yielded = false

    (16..24).each do
      Timecop.freeze(1)

      throttle.choke do
        yielded = true
      end

      expect(yielded).to eql false
    end

    Timecop.return
  end

  it 'yields after the period has passed, even after a previous yield' do
    throttle = ProgressBar::Throttle.new(:throttle_rate  => 10,
                                         :throttle_timer => timer)

    Timecop.freeze(0)

    timer.start

    Timecop.freeze(15)

    throttle.choke {}

    yielded = false

    Timecop.freeze(10)

    throttle.choke do
      yielded = true
    end

    Timecop.return

    expect(yielded).to eql true
  end

  it 'does not throttle if no throttle rate is given' do
    throttle    = Throttle.new(:throttle_timer => timer,
                               :throttle_rate  => nil)
    yield_count = 0

    (1..25).each do
      Timecop.freeze(1)

      throttle.choke do
        yield_count += 1
      end
    end

    Timecop.return

    expect(yield_count).to eql 25
  end
end
end
