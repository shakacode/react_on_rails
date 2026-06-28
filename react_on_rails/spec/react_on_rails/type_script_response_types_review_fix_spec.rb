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

  it "emits raw TypeScript expressions for explicit raw wrappers" do
    described_class.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: {
        starts_at: { raw: "Date" },
        metadata: { raw: "Record<string, string>", optional: true }
      }
    )

    declaration = described_class.to_d_ts

    expect(declaration).to include("  starts_at: Date;")
    expect(declaration).to include("  metadata?: Record<string, string>;")
  end

  it "rejects unsafe raw TypeScript expressions" do
    described_class.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "Date;\nexport type Leak = string" } }
    )

    expect do
      described_class.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "rejects raw TypeScript expressions with unbalanced braces" do
    described_class.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "string } export type Injected = any" } }
    )

    expect do
      described_class.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "requires scalar aliases to use documented lowercase symbols" do
    described_class.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: :String }
    )

    expect do
      described_class.to_d_ts
    end.to raise_error(ReactOnRails::Error, /Unknown scalar response type alias: :String/)
  end

  it "parenthesizes raw composite array members before appending array brackets" do
    described_class.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: {
        project_ids: { array: { raw: "string & { __brand: 'ProjectId' }" } }
      }
    )

    expect(described_class.to_d_ts).to include("  project_ids: (string & { __brand: 'ProjectId' })[];")
  end

  it "reports unknown option keys on wrapper-looking specs" do
    described_class.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        value: { type: :string, nullablee: true }
      }
    )

    expect do
      described_class.to_d_ts
    end.to raise_error(ReactOnRails::Error, /Unrecognized option key\(s\).*:nullablee/)
  end

  it "preserves plain object fields when wrapper-like keys are paired with regular field names" do
    described_class.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        event: { type: :string, source: :string }
      }
    )

    expected_event_type = [
      "  event: {",
      "    type: string;",
      "    source: string;",
      "  };"
    ].join("\n")

    expect(described_class.to_d_ts).to include(expected_event_type)
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
