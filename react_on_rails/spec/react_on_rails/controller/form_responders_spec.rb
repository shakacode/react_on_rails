# frozen_string_literal: true

require_relative "../spec_helper"
require "active_model"
require "react_on_rails/controller/form_responders"

RSpec.describe ReactOnRails::Controller::FormResponders do
  subject(:controller_instance) { controller_class.new }

  let(:controller_class) do
    Class.new do
      include ReactOnRails::Controller::FormResponders

      attr_reader :rendered

      def render(options)
        @rendered = options
      end
    end
  end

  let(:model_class) do
    Class.new do
      include ActiveModel::Model

      attr_accessor :name, :email

      validates :name, presence: true
      validates :email, presence: true, format: { with: /@/, allow_blank: true }

      def self.name
        "TestContact"
      end
    end
  end

  let(:record) { model_class.new(email: "not-an-email").tap(&:validate) }

  describe "#render_model_errors" do
    it "renders the model errors in the { errors: { field: [messages] } } shape" do
      controller_instance.render_model_errors(record)

      expect(controller_instance.rendered[:json]).to eq(
        errors: { name: ["can't be blank"], email: ["is invalid"] }
      )
    end

    it "defaults to HTTP 422" do
      controller_instance.render_model_errors(record)

      expect(controller_instance.rendered[:status]).to eq(422)
    end

    it "allows overriding the status" do
      controller_instance.render_model_errors(record, status: 400)

      expect(controller_instance.rendered[:status]).to eq(400)
    end

    it "rejects symbolic statuses so Rack/Rails status-symbol renames do not change behavior" do
      expect do
        controller_instance.render_model_errors(record, status: :unprocessable_entity)
      end.to raise_error(ArgumentError, /Integer HTTP status/)
    end
  end
end
