# frozen_string_literal: true

module ReactOnRails
  module Controller
    # Opt-in controller helpers for responding to `useRailsForm` submissions
    # (packages/react-on-rails/src/useRailsForm.ts).
    #
    # The hook posts JSON and expects model validation failures as HTTP 422 with
    # the body shape `{ "errors": { "field_name": ["message", ...] } }`. This
    # concern renders exactly that shape from any object exposing ActiveModel
    # errors, so a controller action can stay a plain Rails action:
    #
    #   class ContactMessagesController < ApplicationController
    #     include ReactOnRails::Controller::FormResponders
    #
    #     def create
    #       contact_message = ContactMessage.new(contact_message_params)
    #       if contact_message.save
    #         render json: { message: "Thanks!" }, status: :created
    #       else
    #         render_model_errors(contact_message)
    #       end
    #     end
    #   end
    #
    # Including this concern is optional — `useRailsForm` works against any
    # endpoint that returns the documented shape.
    module FormResponders
      # Renders the validation errors of an ActiveModel/ActiveRecord object as
      # JSON in the shape `useRailsForm` maps onto per-field errors.
      #
      # record: any object responding to `errors` with `ActiveModel::Errors`
      #         (or anything whose `errors` responds to `messages`).
      # status: HTTP status for the response. Defaults to 422 (Unprocessable
      #         Content), which is what the hook's error mapping keys on. The
      #         numeric default sidesteps the Rack 3.1 rename of
      #         :unprocessable_entity to :unprocessable_content.
      def render_model_errors(record, status: 422)
        render json: { errors: record.errors.messages }, status:
      end
    end
  end
end
