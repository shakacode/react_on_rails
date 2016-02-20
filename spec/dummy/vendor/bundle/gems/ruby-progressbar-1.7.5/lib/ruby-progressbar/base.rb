require 'forwardable'

class   ProgressBar
class   Base
  extend Forwardable

  def_delegators :output,
                 :clear,
                 :log,
                 :refresh

  def_delegators :progressable,
                 :progress,
                 :total

  # rubocop:disable Metrics/AbcSize
  def initialize(options = {})
    self.autostart    = options.fetch(:autostart,  true)
    self.autofinish   = options.fetch(:autofinish, true)
    self.finished     = false

    self.timer        = Timer.new(options)
    self.progressable = Progress.new(options)

    options           = options.merge(:timer    => timer,
                                      :progress => progressable)

    self.title_comp   = Components::Title.new(options)
    self.bar          = Components::Bar.new(options)
    self.percentage   = Components::Percentage.new(options)
    self.rate         = Components::Rate.new(options)
    self.time         = Components::Time.new(options)

    self.output       = Output.detect(options.merge(:bar => self))
    @format           = Format::String.new(output.resolve_format(options[:format]))

    start :at => options[:starting_at] if autostart
  end
  # rubocop:enable Metrics/AbcSize

  def start(options = {})
    clear

    timer.start
    update_progress(:start, options)
  end

  def finish
    output.with_refresh do
      self.finished = true
      progressable.finish
      timer.stop
    end unless finished?
  end

  def pause
    output.with_refresh { timer.pause } unless paused?
  end

  def stop
    output.with_refresh { timer.stop } unless stopped?
  end

  def resume
    output.with_refresh { timer.resume } if stopped?
  end

  def reset
    output.with_refresh do
      self.finished = false
      progressable.reset
      timer.reset
    end
  end

  def stopped?
    timer.stopped? || finished?
  end

  alias_method :paused?, :stopped?

  def finished?
    finished || (autofinish && progressable.finished?)
  end

  def started?
    timer.started?
  end

  def decrement
    update_progress(:decrement)
  end

  def increment
    update_progress(:increment)
  end

  def progress=(new_progress)
    update_progress(:progress=, new_progress)
  end

  def total=(new_total)
    update_progress(:total=, new_total)
  end

  def progress_mark=(mark)
    output.refresh_with_format_change { bar.progress_mark = mark }
  end

  def remainder_mark=(mark)
    output.refresh_with_format_change { bar.remainder_mark = mark }
  end

  def title
    title_comp.title
  end

  def title=(title)
    output.refresh_with_format_change { title_comp.title = title }
  end

  def to_s(new_format = nil)
    self.format = new_format if new_format

    Format::Formatter.process(@format, output.length, self)
  end

  def inspect
    "#<ProgressBar:#{progress}/#{total || 'unknown'}>"
  end

  def format=(other)
    output.refresh_with_format_change do
      @format = Format::String.new(other || output.default_format)
    end
  end

  alias_method :format, :format=

  protected

  attr_accessor :output,
                :timer,
                :progressable,
                :title_comp,
                :bar,
                :percentage,
                :rate,
                :time,
                :autostart,
                :autofinish,
                :finished

  def update_progress(*args)
    output.with_refresh do
      progressable.send(*args)
      timer.stop if finished?
    end
  end
end
end
