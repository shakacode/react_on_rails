# frozen_string_literal: true

module ReactOnRails
  DOCTOR_RECOMMENDATION = "For detailed diagnostics, run: bundle exec rake react_on_rails:doctor"

  class Error < StandardError
  end

  class ServerBundleLoadError < Error
  end
end
