require_relative "simplecov_helper"
require_relative "spec_helper"

class CompilerDouble
  attr_reader :times_ran

  def initialize
    @times_ran = 0
  end

  def compile
    @times_ran += 1
  end
end

class ProcessCheckerDouble
  attr_accessor :is_running

  def initialize(p_is_running)
    @is_running = p_is_running
  end

  def running?
    is_running
  end
end

class StatusCheckerDouble
  attr_accessor :up_to_date

  def initialize(initial)
    @up_to_date = initial
  end

  def up_to_date?
    up_to_date
  end
end

module ReactOnRails
  describe EnsureAssetsCompiled do
    let(:compiler) { CompilerDouble.new }
    let(:ensurer) { EnsureAssetsCompiled.new(assets_checker, compiler, process_checker) }

    context "when assets are not up to date" do
      let(:assets_checker) { StatusCheckerDouble.new(false) }

      context "and webpack process is running" do
        let(:process_checker) { ProcessCheckerDouble.new(true) }

        it "sleeps until assets are up to date" do
          thread = Thread.new { ensurer.call }

          sleep 1
          assets_checker.up_to_date = true

          thread.join

          expect(compiler.times_ran).to eq(0)
          expect(ensurer.assets_have_been_compiled).to eq(true)
        end
      end

      context "and webpack process is NOT running" do
        let(:process_checker) { ProcessCheckerDouble.new(false) }

        it "compiles the webpack assets" do
          expect { ensurer.call }.to change { compiler.times_ran }.from(0).to(1)
        end
      end
    end

    context "when assets are up to date" do
      let(:assets_checker) { StatusCheckerDouble.new(true) }
      let(:process_checker) { ProcessCheckerDouble.new(false) }

      it "does nothing" do
        expect { ensurer.call }.not_to change { compiler.times_ran }
      end
    end
  end
end
