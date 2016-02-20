require 'rspectacular'
require 'ruby-progressbar/components/bar'

class     ProgressBar
module    Components
describe  Bar do
  it 'has a default mark when a new bar is created and no parameters are passed' do
    expect(Bar.new.progress_mark).to eql Bar::DEFAULT_PROGRESS_MARK
  end

  it 'has a default remainder mark when a new bar is created and no parameters ' \
     'are passed' do

    expect(Bar.new.remainder_mark).to eql Bar::DEFAULT_REMAINDER_MARK
  end

  it 'returns the overridden mark when a new bar is created and options are passed' do
    progressbar = Bar.new(:progress_mark => 'x')

    expect(progressbar.progress_mark).to eql 'x'
  end

  it 'returns the overridden remainder mark when a new bar is created and options ' \
     'are passed' do

    progressbar = Bar.new(:remainder_mark => 'o')

    expect(progressbar.remainder_mark).to eql 'o'
  end

  it 'displays the bar with no indication of progress when just begun' do
    progress    = Progress.new(:total => 50)
    progressbar = Bar.new(:progress => progress,
                          :length   => 100)

    expect(progressbar.to_s).to eql ' ' * 100
  end

  it 'displays the bar with an indication of progress when nothing has been ' \
     'completed and the bar is incremented' do

    progress    = Progress.new :total    => 50
    progressbar = Bar.new      :progress => progress,
                               :length   => 100
    progress.increment

    expect(progressbar.to_s).to eql '==' + (' ' * 98)
  end

  it 'displays the bar with no indication of progress when nothing has been ' \
     'completed and the bar is incremented' do

    progress    = Progress.new :total    => 50
    progressbar = Bar.new      :progress => progress,
                               :length   => 100

    expect(progressbar.to_s).to eql ' ' * 100
  end

  it 'displays the bar with no indication of progress when a fraction of a percentage ' \
     'has been completed' do

    progress    = Progress.new :total    => 200
    progressbar = Bar.new      :progress => progress,
                               :length   => 100
    progress.start :at => 1

    expect(progressbar.to_s).to eql(' ' * 100)
  end

  it 'displays the bar as 100% complete when completed' do
    progress    = Progress.new :total    => 50
    progressbar = Bar.new      :progress => progress,
                               :length   => 100
    progress.start :at => 50
    progress.increment

    expect(progressbar.to_s).to eql '=' * 100
  end

  it 'displays the bar as 100% complete when completed and the bar is incremented' do
    progress    = Progress.new :total    => 50
    progressbar = Bar.new      :progress => progress,
                               :length   => 100
    progress.start :at => 50
    progress.increment

    expect(progressbar.to_s).to eql '=' * 100
  end

  it 'displays the bar as 98% complete when completed and the bar is decremented' do
    progress    = Progress.new :total    => 50
    progressbar = Bar.new      :progress => progress,
                               :length   => 100
    progress.start :at => 50
    progress.decrement

    expect(progressbar.to_s).to eql(('=' * 98) + (' ' * 2))
  end

  it 'is represented correctly when a bar has an unknown amount to completion' do
    progress    = Progress.new :total    => nil
    progressbar = Bar.new      :progress => progress,
                               :length   => 80

    expect(progressbar.to_s).to eql('=---' * 20)
  end

  it 'is represented after being incremented once when a bar has an unknown amount ' \
     'to completion' do

    progress    = Progress.new :total    => nil
    progressbar = Bar.new      :progress => progress,
                               :length   => 80

    progress.increment

    expect(progressbar.to_s).to eql('-=--' * 20)
  end

  it 'is represented after being incremented twice when a bar has an unknown amount ' \
     'to completion' do

    progress    = Progress.new :total    => nil
    progressbar = Bar.new      :progress => progress,
                               :length   => 80

    2.times { progress.increment }

    expect(progressbar.to_s).to eql('--=-' * 20)
  end

  it 'is represented correctly when a bar has a customized unknown animation' do
    progress    = Progress.new :total                            => nil
    progressbar = Bar.new      :progress                         => progress,
                               :unknown_progress_animation_steps => ['*--', '-*-', '--*'],
                               :length                           => 80

    expect(progressbar.to_s).to eql(('*--' * 26) + '*-')
  end

  it 'displays the bar with an integrated percentage properly when empty' do
    progress    = Progress.new :total    => 100
    progressbar = Bar.new      :progress => progress,
                               :length   => 100

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql ' ' * 100
  end

  it 'displays the bar with an integrated percentage properly just before' \
     'the percentage is displayed' do

    progress    = Progress.new :total    => 100
    progressbar = Bar.new      :progress => progress,
                               :length   => 100

    4.times { progress.increment }

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql '====' + (' ' * 96)
  end

  it 'displays the bar with an integrated percentage properly immediately after' \
     'the percentage is displayed' do

    progress    = Progress.new :total    => 100
    progressbar = Bar.new      :progress => progress,
                               :length   => 100

    5.times { progress.increment }

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql '= 5 =' + (' ' * 95)
  end

  it 'displays the bar with an integrated percentage properly on double digit' \
     'percentage' do

    progress    = Progress.new :total    => 100
    progressbar = Bar.new      :progress => progress,
                               :length   => 100

    10.times { progress.increment }

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql '=== 10 ===' + (' ' * 90)
  end

  it 'displays the bar with an integrated percentage properly when finished' do

    progress    = Progress.new :total    => 100
    progressbar = Bar.new      :progress => progress,
                               :length   => 100
    progress.finish

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql(('=' * 47) + ' 100 ' + ('=' * 48))
  end

  it 'calculates the remaining negative space properly with an integrated percentage ' \
     'bar of 0 percent' do

    progress    = Progress.new :total    => 200
    progressbar = Bar.new      :progress => progress,
                               :length   => 100

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql ' ' * 100

    9.times { progress.increment }

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql '====' + (' ' * 96)

    progress.increment

    bar_text = progressbar.to_s(:format => :integrated_percentage)
    expect(bar_text).to eql '= 5 =' + (' ' * 95)
  end

  it 'raises an error when attempting to set the current value of the bar to be ' \
     'greater than the total' do

    progress     = Progress.new :total    => 10
    _progressbar = Bar.new      :progress => progress

    expect { progress.start :at => 11 }.to \
    raise_error(InvalidProgressError,
                "You can't set the item's current value to be greater than the total.")
  end
end
end
end
