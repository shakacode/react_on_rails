# frozen_string_literal: true

# Receives submissions from the useRailsForm dummy example
# (client/app/startup/RailsFormExample.client.tsx, rendered at /rails_form).
#
# This is a plain Rails action: strong parameters + ActiveModel validations.
# The only useRailsForm-specific piece is the opt-in FormResponders concern,
# whose render_model_errors renders validation failures as
# `{ errors: { field: [messages] } }` with HTTP 422 — the shape the hook maps
# onto per-field errors.
class ContactMessagesController < ApplicationController
  include ReactOnRails::Controller::FormResponders

  def create
    contact_message = ContactMessage.new(contact_message_params)
    if contact_message.valid? # non-persisted model -- validate without saving
      render json: { message: "Thanks, #{contact_message.name}! Your message has been received." },
             status: :created
    else
      render_model_errors(contact_message)
    end
  end

  private

  def contact_message_params
    # useRailsForm posts a flat JSON body; Rails params wrapping may also nest
    # it under :contact_message, so accept both.
    if params.key?(:contact_message)
      params.require(:contact_message).permit(:name, :email, :message)
    else
      params.permit(:name, :email, :message)
    end
  end
end
