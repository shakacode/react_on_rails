# frozen_string_literal: true

require_relative "spec_helper"
require_relative "../track_benchmarks"

# track_benchmarks.rb runs its tracking flow only under `if __FILE__ == $PROGRAM_NAME`,
# so requiring it just loads the helpers. These pin the stderr/exit-code
# classification that decides whether a Bencher run is a real regression (alert) vs
# a missing-baseline retry — the two are mutually exclusive by design: an alert must
# never trigger a start-point-hash retry, or a real regression would be silently
# re-measured against the wrong baseline.
RSpec.describe "track_benchmarks" do
  describe "#alert?" do
    it "is true for a non-zero exit whose stderr names an alert/violation" do
      [
        "Alert: rps boundary violation",
        "Threshold violation detected",
        "found a boundary violation on p90_latency"
      ].each do |stderr|
        expect(alert?(stderr, 1)).to be(true), "expected alert for: #{stderr}"
      end
    end

    it "is false on success even if the text mentions an alert" do
      expect(alert?("Alert: rps boundary violation", 0)).to be(false)
    end

    it "is false for a non-zero exit with no alert phrase (operational failure)" do
      expect(alert?("error: failed to authenticate with the API", 1)).to be(false)
    end
  end

  describe "#retry_without_start_point_hash?" do
    it "is true when the start-point head version is missing and there is no alert" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 1)).to be(true)
    end

    it "is false when an alert is also present (must not retry a real regression)" do
      stderr = "Head Version abc123 not found\nAlert: rps boundary violation"
      expect(retry_without_start_point_hash?(stderr, 1)).to be(false)
      expect(alert?(stderr, 1)).to be(true)
    end

    it "is false on success and for unrelated non-zero failures" do
      expect(retry_without_start_point_hash?("Head Version abc123 not found", 0)).to be(false)
      expect(retry_without_start_point_hash?("some other error", 1)).to be(false)
    end
  end
end
