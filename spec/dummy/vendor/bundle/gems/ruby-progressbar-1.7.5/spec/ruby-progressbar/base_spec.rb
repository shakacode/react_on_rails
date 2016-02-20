require 'spec_helper'
require 'support/time'
require 'stringio'

# rubocop:disable Metrics/LineLength
describe ProgressBar::Base do
  let(:output) do
    StringIO.new('', 'w+').tap do |io|
      allow(io).to receive(:tty?).and_return true
    end
  end

  let(:non_tty_output) do
    StringIO.new('', 'w+').tap do |io|
      allow(io).to receive(:tty?).and_return false
    end
  end

  let(:progressbar) { ProgressBar::Base.new(:output => output, :length => 80, :throttle_rate => 0.0) }

  context 'when the terminal width is shorter than the string being output' do
    it 'can properly handle outputting the bar when the length changes on the fly to less than the minimum width' do
      progressbar = ProgressBar::Base.new(:output => output, :title => 'a' * 25, :format => '%t%B', :throttle_rate => 0.0)

      allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).
                                                                   and_return 30

      progressbar.start

      allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).
                                                                   and_return 20

      progressbar.increment

      output.rewind
      expect(output.read).to match(/\raaaaaaaaaaaaaaaaaaaaaaaaa     \r\s+\raaaaaaaaaaaaaaaaaaaaaaaaa\r\z/)
    end

    context 'and the bar length is calculated' do
      it 'returns the proper string' do
        progressbar = ProgressBar::Base.new(:output => output, :title => ('*' * 21), :starting_at => 5, :total => 10, :autostart => false)

        allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).
                                                                     and_return 20

        expect(progressbar.to_s('%t%w')).to eql '*********************'
      end
    end

    context 'and the incomplete bar length is calculated' do
      it 'returns the proper string' do
        progressbar = ProgressBar::Base.new(:output => output, :title => ('*' * 21), :autostart => false)

        allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).
                                                                     and_return 20

        expect(progressbar.to_s('%t%i')).to eql '*********************'
      end

      it 'returns the proper string' do
        progressbar = ProgressBar::Base.new(:output => output, :title => ('*' * 21), :starting_at => 5, :total => 10, :autostart => false)

        allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).
                                                                     and_return 20

        expect(progressbar.to_s('%t%i')).to eql '*********************'
      end
    end

    context 'and the full bar length is calculated (but lacks the space to output the entire bar)' do
      it 'returns the proper string' do
        progressbar = ProgressBar::Base.new(:output => output, :title => ('*' * 19), :starting_at => 5, :total => 10, :autostart => false)

        allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).
                                                                     and_return 20

        expect(progressbar.to_s('%t%B')).to eql '******************* '
      end

      it 'returns the proper string' do
        progressbar = ProgressBar::Base.new(:output => output, :title => ('*' * 19), :starting_at => 5, :total => 10, :autostart => false)

        allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).
                                                                     and_return 20

        expect(progressbar.to_s('%t%w%i')).to eql '******************* '
      end
    end
  end

  context 'when a new bar is created' do
    context 'and no options are passed' do
      let(:progressbar) { ProgressBar::Base.new  }

      describe '#title' do
        it 'returns the default title' do
          expect(progressbar.send(:title).to_s).to eql ProgressBar::Components::Title::DEFAULT_TITLE
        end
      end

      describe '#output' do
        it 'returns the default output stream' do
          expect(progressbar.send(:output).send(:stream)).to eql ProgressBar::Output::DEFAULT_OUTPUT_STREAM
        end
      end

      describe '#length' do
        context 'when the RUBY_PROGRESS_BAR_LENGTH environment variable exists' do
          before  { ENV['RUBY_PROGRESS_BAR_LENGTH'] = '44' }
          after   { ENV['RUBY_PROGRESS_BAR_LENGTH'] = nil }

          it 'returns the length of the environment variable as an integer' do
            progressbar = ProgressBar::Base.new
            expect(progressbar.send(:output).send(:length_calculator).send(:length)).to eql 44
          end
        end

        context 'when the RUBY_PROGRESS_BAR_LENGTH environment variable does not exist' do
          before  { ENV['RUBY_PROGRESS_BAR_LENGTH'] = nil }

          context 'but the length option was passed in' do
            it 'returns the length specified in the option' do
              progressbar = ProgressBar::Base.new(:length => 88)
              expect(progressbar.send(:output).send(:length_calculator).send(:length)).to eql 88
            end
          end

          context 'and no length option was passed in' do
            it 'returns the width of the terminal if it is a Unix environment' do
              allow(progressbar.send(:output).send(:length_calculator)).to receive(:terminal_width).and_return(99)
              progressbar.send(:output).send(:length_calculator).send(:reset_length)
              expect(progressbar.send(:output).send(:length_calculator).send(:length)).to eql 99
            end

            it 'returns 80 if it is not a Unix environment' do
              allow(progressbar.send(:output).send(:length_calculator)).to receive(:unix?).and_return(false)
              progressbar.send(:output).send(:length_calculator).send(:reset_length)
              expect(progressbar.send(:output).send(:length_calculator).send(:length)).to eql 80
            end
          end
        end
      end
    end

    context 'and options are passed' do
      let(:progressbar) { ProgressBar::Base.new(:title => 'We All Float', :total => 12, :output => STDOUT, :progress_mark => 'x', :length => 88, :starting_at => 5)  }

      describe '#title' do
        it 'returns the overridden title' do
          expect(progressbar.send(:title).to_s).to eql 'We All Float'
        end
      end

      describe '#output' do
        it 'returns the overridden output stream' do
          expect(progressbar.send(:output).send(:stream)).to eql STDOUT
        end
      end

      describe '#length' do
        it 'returns the overridden length' do
          expect(progressbar.send(:output).send(:length_calculator).send(:length)).to eql 88
        end
      end
    end

    context 'if the bar was started 4 minutes ago' do
      before do
        Timecop.travel(-240) do
          progressbar.start
        end
      end

      context 'and within 2 minutes it was halfway done' do
        before do
          Timecop.travel(-120) do
            50.times { progressbar.increment }
          end
        end

        describe '#finish' do
          before do
            Timecop.travel(-120) do
              progressbar.finish
            end
          end

          it 'completes the bar' do
            output.rewind
            expect(output.read).to match(/Progress: \|#{'=' * 68}\|\n/)
          end

          it 'shows the elapsed time instead of the estimated time since the bar is completed' do
            expect(progressbar.to_s('%e')).to eql 'Time: 00:02:00'
          end

          it 'calculates the elapsed time to 00:02:00' do
            expect(progressbar.to_s('%a')).to eql 'Time: 00:02:00'
          end
        end
      end
    end

    context 'which includes ANSI SGR codes in the format string' do
      it 'properly calculates the length of the bar by removing the long version of the ANSI codes from the calculated length' do
        @color_code    = "\e[0m\e[32m\e[7m\e[1m"
        @reset_code    = "\e[0m"
        @progress_mark = "#{@color_code} #{@reset_code}"
        progressbar    = ProgressBar::Base.new(:format        => "#{@color_code}Processing... %b%i#{@reset_code}#{@color_code} %p%%#{@reset_code}",
                                               :progress_mark => @progress_mark,
                                               :output        => output,
                                               :length        => 24,
                                               :starting_at   => 3,
                                               :total         => 6,
                                               :throttle_rate => 0.0)

        progressbar.increment
        progressbar.increment

        output.rewind
        expect(output.read).to include "#{@color_code}Processing... #{@progress_mark * 3}#{' ' * 3}#{@reset_code}#{@color_code} 50%#{@reset_code}\r#{@color_code}Processing... #{@progress_mark * 3}#{' ' * 3}#{@reset_code}#{@color_code} 66%#{@reset_code}\r#{@color_code}Processing... #{@progress_mark * 4}#{' ' * 2}#{@reset_code}#{@color_code} 83%#{@reset_code}\r"
      end

      it 'properly calculates the length of the bar by removing the short version of the ANSI codes from the calculated length' do
        @color_code    = "\e[0;32;7;1m"
        @reset_code    = "\e[0m"
        @progress_mark = "#{@color_code} #{@reset_code}"
        progressbar    = ProgressBar::Base.new(:format        => "#{@color_code}Processing... %b%i#{@reset_code}#{@color_code} %p%%#{@reset_code}",
                                               :progress_mark => @progress_mark,
                                               :output        => output,
                                               :length        => 24,
                                               :starting_at   => 3,
                                               :total         => 6,
                                               :throttle_rate => 0.0)

        progressbar.increment
        progressbar.increment

        output.rewind
        expect(output.read).to include "#{@color_code}Processing... #{@progress_mark * 3}#{' ' * 3}#{@reset_code}#{@color_code} 50%#{@reset_code}\r#{@color_code}Processing... #{@progress_mark * 3}#{' ' * 3}#{@reset_code}#{@color_code} 66%#{@reset_code}\r#{@color_code}Processing... #{@progress_mark * 4}#{' ' * 2}#{@reset_code}#{@color_code} 83%#{@reset_code}\r"
      end
    end

    context 'for a TTY enabled device' do
      it 'can log messages' do
        progressbar = ProgressBar::Base.new(:output => output, :length => 20, :starting_at => 3, :total => 6, :throttle_rate => 0.0)
        progressbar.increment
        progressbar.log 'We All Float'
        progressbar.increment

        output.rewind
        expect(output.read).to include "Progress: |====    |\rProgress: |=====   |\r                    \rWe All Float\nProgress: |=====   |\rProgress: |======  |\r"
      end
    end

    context 'for a non-TTY enabled device' do
      it 'can log messages' do
        progressbar = ProgressBar::Base.new(:output => non_tty_output, :length => 20, :starting_at => 4, :total => 6, :throttle_rate => 0.0)
        progressbar.increment
        progressbar.log 'We All Float'
        progressbar.increment
        progressbar.finish

        non_tty_output.rewind
        expect(non_tty_output.read).to include "We All Float\nProgress: |========|\n"
      end

      it 'can output the bar properly so that it does not spam the screen' do
        progressbar = ProgressBar::Base.new(:output => non_tty_output, :length => 20, :starting_at => 0, :total => 6, :throttle_rate => 0.0)

        6.times { progressbar.increment }

        non_tty_output.rewind
        expect(non_tty_output.read).to eql "\n\nProgress: |========|\n"
      end

      it 'can output the bar properly if finished in the middle of its progress' do
        progressbar = ProgressBar::Base.new(:output => non_tty_output, :length => 20, :starting_at => 0, :total => 6, :throttle_rate => 0.0)

        3.times { progressbar.increment }

        progressbar.finish

        non_tty_output.rewind
        expect(non_tty_output.read).to eql "\n\nProgress: |========|\n"
      end

      it 'can output the bar properly if stopped in the middle of its progress' do
        progressbar = ProgressBar::Base.new(:output => non_tty_output, :length => 20, :starting_at => 0, :total => 6, :throttle_rate => 0.0)

        3.times { progressbar.increment }

        progressbar.stop

        non_tty_output.rewind
        expect(non_tty_output.read).to eql "\n\nProgress: |====\n"
      end

      it 'ignores changes to the title due to the fact that the bar length cannot change' do
        progressbar = ProgressBar::Base.new(:output => non_tty_output, :length => 20, :starting_at => 0, :total => 6, :throttle_rate => 0.0)

        3.times { progressbar.increment }

        progressbar.title = 'Testing'
        progressbar.stop

        non_tty_output.rewind

        expect(non_tty_output.read).to eql "\n\nProgress: |====\n"
      end

      it 'allows the title to be customized when the bar is created' do
        progressbar = ProgressBar::Base.new(:output => non_tty_output, :title => 'Custom', :length => 20, :starting_at => 0, :total => 6, :throttle_rate => 0.0)

        3.times { progressbar.increment }

        progressbar.stop

        non_tty_output.rewind

        expect(non_tty_output.read).to eql "\n\nCustom: |=====\n"
      end
    end
  end

  context 'when a bar is about to be completed' do
    let(:progressbar) { ProgressBar::Base.new(:starting_at => 5, :total => 6, :output => output, :length => 20, :throttle_rate => 0.0) }

    context 'and it is incremented' do
      before { progressbar.increment }

      it 'registers as being "finished"' do
        expect(progressbar).to be_finished
      end

      it 'prints a new line' do
        output.rewind
        expect(output.read.end_with?("\n")).to eql true
      end

      it 'does not continue to print bars if finish is subsequently called' do
        progressbar.finish

        output.rewind
        expect(output.read).to end_with "                    \rProgress: |======  |\rProgress: |========|\n"
      end
    end
  end

  context 'when a bar with autofinish=false is about to be completed' do
    let(:progressbar) { ProgressBar::Base.new(:autofinish => false, :starting_at => 5, :total => 6, :output => output, :length => 20, :throttle_rate => 0.0) }

    context 'and it is incremented' do
      before { progressbar.increment }

      it 'does not automatically finish' do
        expect(progressbar).not_to be_finished
      end

      it 'does not prints a new line' do
        output.rewind

        expect(output.read.end_with?("\n")).to eql false
      end

      it 'allows reset' do
        progressbar.finish
        expect(progressbar).to be_finished

        progressbar.reset

        expect(progressbar).not_to be_finished
      end

      it 'does prints a new line when manually finished' do
        progressbar.finish
        expect(progressbar).to be_finished

        output.rewind

        expect(output.read.end_with?("\n")).to eql true
      end

      it 'does not continue to print bars if finish is subsequently called' do
        progressbar.finish

        output.rewind

        expect(output.read).to end_with "                    \rProgress: |======  |\rProgress: |========|\rProgress: |========|\n"
      end
    end
  end

  context 'when a bar has an unknown amount to completion' do
    let(:progressbar) { ProgressBar::Base.new(:total => nil, :output => output, :length => 80, :unknown_progress_animation_steps => ['=--', '-=-', '--=']) }

    it 'is represented correctly' do
      expect(progressbar.to_s('%i')).to eql '=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=-'
    end

    it 'is represented after being incremented once' do
      progressbar.increment
      expect(progressbar.to_s('%i')).to eql '-=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--='
    end

    it 'is represented after being incremented twice' do
      progressbar.increment
      progressbar.increment
      expect(progressbar.to_s('%i')).to eql '--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--'
    end

    it 'displays the proper ETA' do
      progressbar.increment

      expect(progressbar.to_s('%i%e')).to eql '-=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=- ETA: ??:??:??'
      expect(progressbar.to_s('%i%E')).to eql '-=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=--=- ETA: ??:??:??'
    end
  end

  context 'when a bar is started' do
    let(:progressbar) { ProgressBar::Base.new(:starting_at => 0, :total => 100, :output => output, :length => 80, :throttle_rate  => 0.0) }

    context 'and it is incremented any number of times' do
      before { 10.times { progressbar.increment } }

      describe '#progress_mark=' do
        it 'changes the mark used to represent progress and updates the output' do
          progressbar.progress_mark = 'x'

          output.rewind
          expect(output.read).to match(/\rProgress: \|xxxxxx#{' ' * 62}\|\r\z/)
        end
      end

      describe '#remainder_mark=' do
        it 'changes the mark used to represent the remaining part of the bar and updates the output' do
          progressbar.remainder_mark = 'x'

          output.rewind
          expect(output.read).to match(/\rProgress: \|======#{'x' * 62}\|\r\z/)
        end
      end

      describe '#title=' do
        it 'changes the title used to represent the items being progressed and updates the output' do
          progressbar.title = 'Items'

          output.rewind
          expect(output.read).to match(/\rItems: \|=======#{' ' * 64}\|\r\z/)
        end
      end

      describe '#reset' do
        before { progressbar.reset }

        it 'resets the bar back to the starting value' do
          output.rewind
          expect(output.read).to match(/\rProgress: \|#{' ' * 68}\|\r\z/)
        end
      end

      describe '#stop' do
        before { progressbar.stop }

        it 'forcibly halts the bar wherever it is and cancels it' do
          output.rewind
          expect(output.read).to match(/\rProgress: \|======#{' ' * 62}\|\n\z/)
        end

        it 'does not output the bar multiple times if the bar is already stopped' do
          output.rewind
          progressbar.stop
          output.rewind

          expect(output.read).to start_with "#{' ' * 80}"
        end
      end

      describe '#resume' do
        it 'does not output the bar multiple times' do
          output.rewind
          progressbar.resume
          output.rewind

          expect(output.read).to start_with "#{' ' * 80}"
        end
      end
    end
  end

  context 'when a bar is started from 10/100' do
    let(:progressbar) { ProgressBar::Base.new(:starting_at => 10, :total => 100, :output => output, :length => 112) }

    context 'and it is incremented any number of times' do
      before { 10.times { progressbar.increment } }

      describe '#reset' do
        before { progressbar.reset }

        it 'resets the bar back to the starting value' do
          output.rewind
          expect(output.read).to match(/\rProgress: \|==========#{' ' * 90}\|\r\z/)
        end
      end
    end
  end

  describe '#clear' do
    it 'clears the current terminal line and/or bar text' do
      progressbar.clear

      output.rewind
      expect(output.read).to match(/^#{progressbar.send(:output).send(:clear_string)}/)
    end
  end

  describe '#start' do
    it 'clears the current terminal line' do
      progressbar.start

      output.rewind
      expect(output.read).to match(/^#{progressbar.send(:output).send(:clear_string)}/)
    end

    it 'prints the bar for the first time' do
      progressbar.start

      output.rewind
      expect(output.read).to match(/Progress: \|                                                                    \|\r\z/)
    end

    it 'prints correctly if passed a position to start at' do
      progressbar.start(:at => 20)

      output.rewind
      expect(output.read).to match(/Progress: \|=============                                                       \|\r\z/)
    end
  end

  context 'when the bar has not been completed' do
    let(:progressbar) { ProgressBar::Base.new(:length => 112, :starting_at => 0, :total => 50, :output => output, :throttle_rate => 0.0)  }

    describe '#increment' do
      before { progressbar.increment }

      it 'displays the bar with the correct formatting' do
        output.rewind
        expect(output.read).to match(/Progress: \|==                                                                                                  \|\r\z/)
      end
    end
  end

  context 'when a new bar is created with a specific format' do
    context '#format' do
      let(:progressbar) { ProgressBar::Base.new(:format => '%B %p%%') }

      context 'if called with no arguments' do
        before { progressbar.format = nil }

        it 'resets the format back to the default' do
          expect(progressbar.to_s).to match(/^Progress: \|\s+\|\z/)
        end
      end

      context 'if called with a specific format string' do
        before { progressbar.format = '%t' }

        it 'sets it as the new format for the bar' do
          expect(progressbar.to_s).to match(/^Progress\z/)
        end
      end
    end

    context '#to_s' do
      context 'when no time has elapsed' do
        it 'displays zero for the rate' do
          Timecop.freeze do
            progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 0)

            expect(progressbar.to_s('%r')).to match(/^0\z/)
          end
        end
      end

      context 'when any time has elasped' do
        context 'and the standard rate is applied' do
          it 'displays zero for %r if no progress has been made' do
            progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)

            Timecop.travel(2) do
              expect(progressbar.to_s('%r')).to match(/^0\z/)
            end
          end

          it 'displays zero for %R if no progress has been made' do
            progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)

            Timecop.travel(2) do
              expect(progressbar.to_s('%R')).to match(/^0.00\z/)
            end
          end

          it 'takes into account the starting position when calculating %r' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)
              progressbar.start
              progressbar.progress += 20

              Timecop.travel(2) do
                expect(progressbar.to_s('%r')).to match(/^10\z/)
              end
            end
          end

          it 'takes into account the starting position when calculating %R' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)
              progressbar.start
              progressbar.progress += 13

              Timecop.travel(2) do
                expect(progressbar.to_s('%R')).to match(/^6.50\z/)
              end
            end
          end

          it 'displays the rate when passed the "%r" format flag' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 0)
              progressbar.start
              progressbar.progress += 20

              Timecop.travel(2) do
                expect(progressbar.to_s('%r')).to match(/^10\z/)
              end
            end
          end

          it 'displays the rate when passed the "%R" format flag' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 0)
              progressbar.start
              progressbar.progress += 10

              Timecop.travel(6) do
                expect(progressbar.to_s('%R')).to match(/^1.67\z/)
              end
            end
          end
        end

        context 'and the a custom rate is applied' do
          it 'displays zero for %r if no progress has been made' do
            progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20, :rate_scale => lambda { |rate| rate / 2 })

            Timecop.travel(2) do
              expect(progressbar.to_s('%r')).to match(/^0\z/)
            end
          end

          it 'displays zero for %R if no progress has been made' do
            progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20, :rate_scale => lambda { |rate| rate / 2 })

            Timecop.travel(2) do
              expect(progressbar.to_s('%R')).to match(/^0.00\z/)
            end
          end

          it 'takes into account the starting position when calculating %r' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20, :rate_scale => lambda { |rate| rate / 2 })
              progressbar.start
              progressbar.progress += 20

              Timecop.travel(2) do
                expect(progressbar.to_s('%r')).to match(/^5\z/)
              end
            end
          end

          it 'takes into account the starting position when calculating %R' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20, :rate_scale => lambda { |rate| rate / 2 })
              progressbar.start
              progressbar.progress += 13

              Timecop.travel(2) do
                expect(progressbar.to_s('%R')).to match(/^3.25\z/)
              end
            end
          end

          it 'displays the rate when passed the "%r" format flag' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 0, :rate_scale => lambda { |rate| rate / 2 })
              progressbar.start
              progressbar.progress += 20

              Timecop.travel(2) do
                expect(progressbar.to_s('%r')).to match(/^5\z/)
              end
            end
          end

          it 'displays the rate when passed the "%R" format flag' do
            Timecop.freeze do
              progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 0, :rate_scale => lambda { |rate| rate / 2 })
              progressbar.start
              progressbar.progress += 10

              Timecop.travel(6) do
                expect(progressbar.to_s('%R')).to match(/^0.83\z/)
              end
            end
          end
        end
      end

      it 'displays the title when passed the "%t" format flag' do
        expect(progressbar.to_s('%t')).to match(/^Progress\z/)
      end

      it 'displays the title when passed the "%T" format flag' do
        expect(progressbar.to_s('%T')).to match(/^Progress\z/)
      end

      it 'displays the bar when passed the "%B" format flag (including empty space)' do
        progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)
        expect(progressbar.to_s('%B')).to match(/^#{'=' * 20}#{' ' * 80}\z/)
      end

      it 'displays the bar when passed the combined "%b%i" format flags' do
        progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)
        expect(progressbar.to_s('%b%i')).to match(/^#{'=' * 20}#{' ' * 80}\z/)
      end

      it 'displays the bar when passed the "%b" format flag (excluding empty space)' do
        progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)
        expect(progressbar.to_s('%b')).to match(/^#{'=' * 20}\z/)
      end

      it 'displays the incomplete space when passed the "%i" format flag' do
        progressbar = ProgressBar::Base.new(:length => 100, :starting_at => 20)
        expect(progressbar.to_s('%i')).to match(/^#{' ' * 80}\z/)
      end

      it 'displays the bar when passed the "%w" format flag' do
        progressbar = ProgressBar::Base.new(:output => output, :length => 100, :starting_at => 0)

        expect(progressbar.to_s('%w')).to match(/^\z/)
        4.times { progressbar.increment }
        expect(progressbar.to_s('%w')).to match(/^====\z/)
        progressbar.increment
        expect(progressbar.to_s('%w')).to match(/^= 5 =\z/)
        5.times { progressbar.increment }
        expect(progressbar.to_s('%w')).to match(/^=== 10 ===\z/)
        progressbar.decrement
        expect(progressbar.to_s('%w')).to match(/^=== 9 ===\z/)
        91.times { progressbar.increment }
        expect(progressbar.to_s('%w')).to match(/^#{'=' * 47} 100 #{'=' * 48}\z/)
      end

      it 'calculates the remaining negative space properly with an integrated percentage bar of 0 percent' do
        progressbar = ProgressBar::Base.new(:output => output, :length => 100, :total => 200, :starting_at => 0)

        expect(progressbar.to_s('%w%i')).to match(/^\s{100}\z/)
        9.times { progressbar.increment }
        expect(progressbar.to_s('%w%i')).to match(/^====\s{96}\z/)
        progressbar.increment
        expect(progressbar.to_s('%w%i')).to match(/^= 5 =\s{95}\z/)
      end

      it 'can display a percentage, even if the total is unknown' do
        progressbar = ProgressBar::Base.new(:output => output, :length => 100, :total => nil, :starting_at => 0)

        expect(progressbar.to_s('%p')).to match(/\A0\z/)
        expect(progressbar.to_s('%P')).to match(/\A0\.0\z/)
      end

      it 'can display a percentage, even if the total is zero' do
        progressbar = ProgressBar::Base.new(:output => output, :length => 100, :total => 0, :starting_at => 0)

        expect(progressbar.to_s('%p')).to match(/\A100\z/)
        expect(progressbar.to_s('%P')).to match(/\A100\.0\z/)
      end

      it 'displays the current capacity when passed the "%c" format flag' do
        progressbar = ProgressBar::Base.new(:output => output, :starting_at => 0)

        expect(progressbar.to_s('%c')).to match(/^0\z/)
        progressbar.increment
        expect(progressbar.to_s('%c')).to match(/^1\z/)
        progressbar.decrement
        expect(progressbar.to_s('%c')).to match(/^0\z/)
      end

      it 'displays the total capacity when passed the "%C" format flag' do
        progressbar = ProgressBar::Base.new(:total => 100)

        expect(progressbar.to_s('%C')).to match(/^100\z/)
      end

      it 'displays the percentage complete when passed the "%p" format flag' do
        progressbar = ProgressBar::Base.new(:starting_at => 33, :total => 200)

        expect(progressbar.to_s('%p')).to match(/^16\z/)
      end

      it 'displays the justified percentage complete when passed the "%j" format flag' do
        progressbar = ProgressBar::Base.new(:starting_at => 33, :total => 200)

        expect(progressbar.to_s('%j')).to match(/^ 16\z/)
      end

      it 'displays the percentage complete when passed the "%P" format flag' do
        progressbar = ProgressBar::Base.new(:starting_at => 33, :total => 200)

        expect(progressbar.to_s('%P')).to match(/^16.50\z/)
      end

      it 'displays the justified percentage complete when passed the "%J" format flag' do
        progressbar = ProgressBar::Base.new(:starting_at => 33, :total => 200)

        expect(progressbar.to_s('%J')).to match(/^ 16.50\z/)
      end

      it 'displays only up to 2 decimal places when using the "%P" flag' do
        progressbar = ProgressBar::Base.new(:starting_at => 66, :total => 99)

        expect(progressbar.to_s('%P')).to match(/^66.66\z/)
      end

      it 'displays a literal percent sign when using the "%%" flag' do
        progressbar = ProgressBar::Base.new(:starting_at => 66, :total => 99)

        expect(progressbar.to_s('%%')).to match(/^%\z/)
      end

      it 'displays a literal percent sign when using the "%%" flag' do
        progressbar = ProgressBar::Base.new(:starting_at => 66, :total => 99)

        expect(progressbar.to_s('%%')).to match(/^%\z/)
      end

      context 'when called after #start' do
        before do
          Timecop.travel(-3_723) do
            progressbar.start
          end
        end

        context 'and the bar is reset' do
          before { progressbar.reset }

          it 'displays "??:??:??" until finished when passed the %e flag' do
            expect(progressbar.to_s('%a')).to match(/^Time: --:--:--\z/)
          end
        end

        it 'displays the time elapsed when using the "%a" flag' do
          expect(progressbar.to_s('%a')).to match(/^Time: 01:02:03\z/)
        end
      end

      context 'when called before #start' do
        it 'displays unknown time until finished when passed the "%e" flag' do
          progressbar = ProgressBar::Base.new
          expect(progressbar.to_s('%e')).to match(/^ ETA: \?\?:\?\?:\?\?\z/)
        end

        context 'when started_at is set to a value greater than 0' do
          it 'displays unknown time until finished when passed the "%e" flag' do
            progressbar = ProgressBar::Base.new(:starting_at =>  1)
            expect(progressbar.to_s('%e')).to match(/^ ETA: \?\?:\?\?:\?\?\z/)
          end
        end
      end

      context 'when called after #start' do
        let(:progressbar) do
          Timecop.travel(-3_723) do
            progressbar = ProgressBar::Base.new(:starting_at => 0, :output => output, :smoothing => 0.0)
            progressbar.start
            progressbar.progress = 50
            progressbar
          end
        end

        context 'and the bar is reset' do
          before { progressbar.reset }

          it 'displays "??:??:??" until finished when passed the "%e" flag' do
            expect(progressbar.to_s('%e')).to match(/^ ETA: \?\?:\?\?:\?\?\z/)
          end
        end

        it 'displays the estimated time remaining when using the "%e" flag' do
          expect(progressbar.to_s('%e')).to match(/^ ETA: 01:02:03\z/)
        end
      end

      context 'when it could take 100 hours or longer to finish' do
        let(:progressbar) do
          Timecop.travel(-120_000) do
            progressbar = ProgressBar::Base.new(:starting_at => 0, :total => 100, :output => output, :smoothing => 0.0)
            progressbar.start
            progressbar.progress = 25
            progressbar
          end
        end

        it 'displays "> 4 Days" until finished when passed the "%E" flag' do
          expect(progressbar.to_s('%E')).to match(/^ ETA: > 4 Days\z/)
        end

        it 'displays "??:??:??" until finished when passed the "%e" flag' do
          expect(progressbar.to_s('%e')).to match(/^ ETA: \?\?:\?\?:\?\?\z/)
        end

        it 'displays the exact estimated time until finished when passed the "%f" flag' do
          expect(progressbar.to_s('%f')).to match(/^ ETA: 100:00:00\z/)
        end
      end
    end
  end

  context 'when the bar is started after having total set to 0' do
    let(:progressbar) { ProgressBar::Base.new(:output => output, :autostart => false) }

    it 'does not throw an error' do
      progressbar.total = 0

      expect { progressbar.start }.not_to raise_error
    end
  end

  context 'when the bar has no items to process' do
    context 'and it has not been started' do
      let(:progressbar) { ProgressBar::Base.new(:started_at => 0, :total => 0, :autostart => false, :smoothing => 0.0, :format => ' %c/%C |%w>%i| %e ', :output => output) }

      it 'does not throw an error if told to stop' do
        progressbar.stop

        expect { progressbar.start }.not_to raise_error
      end
    end
  end
end
# rubocop:enable Metrics/LineLength
