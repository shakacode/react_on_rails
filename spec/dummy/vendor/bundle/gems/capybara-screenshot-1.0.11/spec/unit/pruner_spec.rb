require 'spec_helper'

describe Capybara::Screenshot::Pruner do
  describe '#initialize' do
    let(:pruner) { Capybara::Screenshot::Pruner.new(strategy) }

    context 'accepts generic strategies:' do
      [:keep_all, :keep_last_run].each do |strategy_sym|
        let(:strategy) { strategy_sym }

        it ":#{strategy_sym}" do
          expect(pruner.strategy).to eq(strategy)
        end
      end
    end

    context 'keep:int' do
      let(:strategy) { { keep: 50 } }

      it 'is a suitable strategy' do
        expect(pruner.strategy).to eq(strategy)
      end
    end

    context 'invalid strategy' do
      context 'symbol' do
        let(:strategy) { :invalid_strategy }

        it 'raises an error' do
          expect { pruner }.to raise_error
        end
      end

      context 'keep:sym' do
        let(:strategy) { { keep: :symbol } }

        it 'raises an error' do
          expect { pruner }.to raise_error
        end
      end
    end
  end

  describe '#prune_old_screenshots' do
    let(:capybara_root)   { Capybara::Screenshot.capybara_root }
    let(:remaining_files) { Dir.glob(File.expand_path('*', capybara_root)).sort }
    let(:files_created)   { [] }
    let(:files_count)     { 8 }
    let(:pruner)         { Capybara::Screenshot::Pruner.new(strategy) }

    before do
      allow(Capybara::Screenshot).to receive(:capybara_root).and_return(Dir.mktmpdir.to_s)

      files_count.times do |i|
        files_created << FileUtils.touch("#{capybara_root}/#{i}.#{i % 2 == 0 ? 'png' : 'html'}").first.tap do |file_name|
          File.utime(Time.now, Time.now - files_count + i, file_name)
        end
      end

      pruner.prune_old_screenshots
    end

    after do
      FileUtils.rm_rf capybara_root
    end

    context 'with :keep_all strategy' do
      let(:strategy) { :keep_all }

      it 'should not remove screens' do
        expect(remaining_files).to eq(files_created)
      end
    end

    context 'with :keep_last_run strategy' do
      let(:strategy) { :keep_last_run }

      it 'should remove all screens' do
        expect(remaining_files).to be_empty
      end

      context 'when dir is missing' do
        before { FileUtils.rm_rf(Capybara::Screenshot.capybara_root) }

        it 'should not raise error' do
          expect { pruner.prune_old_screenshots }.to_not raise_error
        end
      end
    end

    context 'with :keep strategy' do
      let(:keep_count) { 3 }
      let(:strategy) { { keep: keep_count } }

      it 'should keep specified number of screens' do
        expect(remaining_files).to eq(files_created.last(keep_count))
      end

      context 'when dir is missing' do
        before { FileUtils.rm_rf(Capybara::Screenshot.capybara_root) }

        it 'should not raise error when dir is missing' do
          expect { pruner.prune_old_screenshots }.to_not raise_error
        end
      end
    end
  end
end
