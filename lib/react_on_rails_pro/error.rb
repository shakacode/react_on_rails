# frozen_string_literal: true

require "react_on_rails/error"

module ReactOnRailsPro
  class Error < ::ReactOnRails::Error
    def self.raise_duplicate_bundle_upload_error
      raise ReactOnRailsPro::Error,
            "The bundle has already been uploaded, " \
            "but the server is still sending the send_bundle status code. " \
            "This is unexpected behavior."
    end
  end
end
