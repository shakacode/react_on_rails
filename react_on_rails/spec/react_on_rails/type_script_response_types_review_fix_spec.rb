# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe ReactOnRails::TypeScriptResponseTypes do
  before { described_class.reset! }

  after { described_class.reset! }

  it "rejects optional array member wrappers" do
    described_class.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        values: { array: { type: :string, optional: true } }
      }
    )

    expect do
      described_class.to_d_ts
    end.to raise_error(ReactOnRails::Error, /array elements cannot be optional/)
  end

  it "omits keyed response helpers when no responses are registered" do
    described_class.define_type("Project", fields: { id: :number })

    declaration = described_class.to_d_ts

    expect(declaration).to include("export interface Project")
    expect(declaration).to include("export interface RailsResponseTypes {}")
    expect(declaration).not_to include("export type RailsResponseTypeName")
    expect(declaration).not_to include("export type RailsResponseType<")
  end
end
