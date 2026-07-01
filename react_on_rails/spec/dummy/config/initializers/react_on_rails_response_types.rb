# frozen_string_literal: true

# Dummy-app contract used by the typed Rails action example.
# Regenerate with:
#   REACT_ON_RAILS_RESPONSE_TYPES_OUT=client/app/types/react_on_rails_response_types.d.ts \
#     bundle exec rake react_on_rails:generate_response_types
ReactOnRails::TypeScriptResponseTypes.define_response(
  "contact_messages.create",
  type_name: "ContactMessagesCreateResponse",
  fields: {
    message: :string
  }
)

ReactOnRails::TypeScriptResponseTypes.define_response(
  "contact_messages.validation_error",
  type_name: "ContactMessagesValidationErrorResponse",
  fields: {
    errors: {
      fields: {
        base: { array: :string, optional: true },
        email: { array: :string, optional: true },
        message: { array: :string, optional: true },
        name: { array: :string, optional: true }
      }
    }
  }
)
