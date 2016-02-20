require 'rspectacular'
require 'ruby-progressbar/progress'

class     ProgressBar
describe  Progress do
  it 'knows the default total when no parameters are passed' do
    progress = Progress.new

    expect(progress.total).to eql Progress::DEFAULT_TOTAL
  end

  it 'knows the default beginning progress when no parameters are passed and ' \
     'the progress has not been started' do

    progress = Progress.new

    expect(progress.progress).to be_zero
  end

  it 'knows the default starting value when no parameters are passed and the ' \
     'progress has been started' do

    progress = Progress.new

    progress.start

    expect(progress.progress).to eql Progress::DEFAULT_BEGINNING_POSITION
  end

  it 'knows the given starting value when no parameters are passed and the ' \
     'progress is started with a starting value' do

    progress = Progress.new

    progress.start :at => 10

    expect(progress.progress).to eql 10
  end

  it 'knows the overridden total when the total is passed in' do
    progress = Progress.new(:total          => 12,
                            :progress_mark  => 'x',
                            :remainder_mark => '.')

    expect(progress.total).to eql 12
  end

  it 'knows the percentage completed when begun with no progress' do
    progress = Progress.new

    progress.start

    expect(progress.percentage_completed).to eql 0
  end

  it 'knows the progress after it has been incremented' do
    progress = Progress.new

    progress.start
    progress.increment

    expect(progress.progress).to eql 1
  end

  it 'knows the percentage completed after it has been incremented' do
    progress = Progress.new(:total => 50)

    progress.start
    progress.increment

    expect(progress.percentage_completed).to eql 2
  end

  it 'knows to always round down the percentage completed' do
    progress = Progress.new(:total => 200)

    progress.start :at => 1

    expect(progress.percentage_completed).to eql 0
  end

  it 'cannot increment past the total' do
    progress = Progress.new(:total => 50)

    progress.start :at => 50
    progress.increment

    expect(progress.progress).to eql 50
    expect(progress.percentage_completed).to eql 100
  end

  it 'allow progress to be decremented once it is finished' do
    progress = Progress.new(:total => 50)

    progress.start :at => 50
    progress.decrement

    expect(progress.progress).to eql 49
    expect(progress.percentage_completed).to eql 98
  end

  it 'knows the running average even when progress has been made' do
    progress = Progress.new(:total => 50)

    progress.running_average = 10
    progress.start :at => 0

    expect(progress.running_average).to be_zero

    progress.progress += 40

    expect(progress.running_average).to eql 36.0
  end

  it 'knows the running average is reset even after progress is started' do
    progress = Progress.new(:total => 50)

    progress.running_average = 10
    progress.start :at => 0

    expect(progress.running_average).to be_zero

    progress.start :at => 40

    expect(progress.running_average).to eql 0.0
  end

  it 'allows the default smoothing to be overridden' do
    expect(Progress.new(:smoothing => 0.3).smoothing).to eql 0.3
  end

  it 'has a default smoothing value' do
    expect(Progress.new.smoothing).to eql 0.1
  end

  it 'knows the percentage completed is 100% if the total is zero' do
    progress = Progress.new(:total => 0)

    expect(progress.percentage_completed).to eql 100
  end

  it 'raises an error when passed a number larger than the total' do
    progress = Progress.new(:total => 100)

    expect { progress.progress = 101 }.to \
    raise_error(InvalidProgressError,
                "You can't set the item's current value to be greater than the total.")
  end
end
end
