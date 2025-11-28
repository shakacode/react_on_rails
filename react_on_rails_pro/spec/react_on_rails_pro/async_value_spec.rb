# frozen_string_literal: true

require_relative "spec_helper"
require "async"
require "async/barrier"

module ReactOnRailsPro
  RSpec.describe AsyncValue do
    describe "#value" do
      it "returns the task result when task completes successfully" do
        Sync do
          task = Async do
            "<div>Hello</div>"
          end

          async_value = described_class.new(task: task)
          expect(async_value.value).to eq("<div>Hello</div>")
        end
      end

      it "re-raises exception when task fails" do
        Sync do
          task = Async do
            raise StandardError, "Render failed"
          end

          async_value = described_class.new(task: task)
          expect { async_value.value }.to raise_error(StandardError, "Render failed")
        end
      end
    end

    describe "#resolved?" do
      it "returns false when task is not finished" do
        Sync do
          barrier = Async::Barrier.new

          task = barrier.async do
            sleep 0.1
            "result"
          end

          async_value = described_class.new(task: task)
          expect(async_value.resolved?).to be false

          barrier.wait
        end
      end

      it "returns true when task is finished" do
        Sync do
          task = Async do
            "result"
          end

          task.wait
          async_value = described_class.new(task: task)
          expect(async_value.resolved?).to be true
        end
      end
    end

    describe "#to_s" do
      it "returns the string representation of the value" do
        Sync do
          task = Async do
            "<div>Content</div>"
          end

          async_value = described_class.new(task: task)
          expect(async_value.to_s).to eq("<div>Content</div>")
        end
      end
    end

    describe "#html_safe" do
      it "returns the html_safe version of the value" do
        Sync do
          task = Async do
            "<div>Content</div>"
          end

          async_value = described_class.new(task: task)
          result = async_value.html_safe

          expect(result).to be_html_safe
          expect(result).to eq("<div>Content</div>")
        end
      end
    end
  end
end
