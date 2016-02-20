require 'rspectacular'
require 'ruby-progressbar/calculators/running_average'

class     ProgressBar
module    Calculators
describe  RunningAverage do
  it 'can properly calculate a running average' do
    first_average = RunningAverage.calculate(4.5,  12,  0.1)
    expect(first_average).to be_within(0.001).of 11.25

    second_average = RunningAverage.calculate(8.2,  51,  0.7)
    expect(second_average).to be_within(0.001).of 21.04

    third_average = RunningAverage.calculate(41.8, 100, 0.59)
    expect(third_average).to be_within(0.001).of 65.662
  end
end
end
end
