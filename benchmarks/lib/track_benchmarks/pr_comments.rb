# frozen_string_literal: true

module TrackBenchmarks
  # PR-comment replacement gate for benchmark reports.
  module PrComments
    module_function

    def replace(markdown, event_name: ENV.fetch("GITHUB_EVENT_NAME", nil))
      return unless event_name == "pull_request"
      return if markdown.empty?

      yield.replace(markdown)
    end
  end
end
