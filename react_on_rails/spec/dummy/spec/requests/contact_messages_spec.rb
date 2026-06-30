# frozen_string_literal: true

require "rails_helper"

# Round-trip coverage for the useRailsForm contract against a plain Rails
# controller using the opt-in ReactOnRails::Controller::FormResponders concern:
# an invalid submit responds 422 with `{ errors: { field: [messages] } }` (the
# exact shape the hook maps onto per-field errors), and a valid submit succeeds.
describe "ContactMessages (useRailsForm 422 round trip)" do
  let(:json_headers) do
    # Matches what useRailsForm sends (minus the CSRF header, which Rails does
    # not enforce in the test environment).
    {
      "CONTENT_TYPE" => "application/json",
      "ACCEPT" => "application/json",
      "X-Requested-With" => "XMLHttpRequest"
    }
  end

  describe "POST /contact_messages with invalid data" do
    before do
      post "/contact_messages",
           params: { name: "", email: "not-an-email", message: "too short" }.to_json,
           headers: json_headers
    end

    it "responds with HTTP 422" do
      expect(response).to have_http_status(422)
    end

    it "renders per-field errors in the shape useRailsForm expects" do
      errors = response.parsed_body.fetch("errors")

      expect(errors).to include(
        "name" => ["can't be blank"],
        "email" => ["is invalid"],
        "message" => [a_string_matching(/too short/)]
      )
    end

    it "renders every message as an array of strings" do
      errors = response.parsed_body.fetch("errors")

      expect(errors.values).to all(all(be_a(String)))
    end
  end

  describe "POST /contact_messages with valid data" do
    before do
      post "/contact_messages",
           params: { name: "Ada", email: "ada@example.com", message: "A long enough message." }.to_json,
           headers: json_headers
    end

    it "responds with HTTP 201" do
      expect(response).to have_http_status(:created)
    end

    it "returns the success payload" do
      expect(response.parsed_body.fetch("message")).to include("Ada")
    end
  end

  describe "POST /contact_messages with wrapped valid data" do
    before do
      post "/contact_messages",
           params: {
             contact_message: { name: "Ada", email: "ada@example.com", message: "A long enough message." }
           }.to_json,
           headers: json_headers
    end

    it "accepts Rails params wrapping" do
      expect(response).to have_http_status(:created)
    end
  end

  describe "GET /rails_form" do
    it "renders the form example page" do
      get "/rails_form"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("useRailsForm 422 round trip")
    end
  end

  describe "React on Rails response type contract" do
    it "registers the contact message responses used by the typed Rails action example" do
      generated_types = ReactOnRails::TypeScriptResponseTypes.to_d_ts

      expect(generated_types).to include('"contact_messages.create": ContactMessagesCreateResponse;')
      expect(generated_types).to include('"contact_messages.validation_error": ContactMessagesValidationErrorResponse;')
      expect(generated_types).to include("message: string;")
      expect(generated_types).to include("email?: string[];")
    end
  end
end
