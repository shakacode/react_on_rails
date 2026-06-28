# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "TypeScript response type raw validation" do
  let(:response_types) { ReactOnRails::TypeScriptResponseTypes }

  before { response_types.reset! }

  after { response_types.reset! }

  it "rejects optional array member wrappers" do
    response_types.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        values: { array: { type: :string, optional: true } }
      }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /array elements cannot be optional/)
  end

  it "emits raw TypeScript expressions for explicit raw wrappers" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: {
        starts_at: { raw: "Date" },
        metadata: { raw: "Record<string, { value: number, label: string }>", optional: true }
      }
    )

    declaration = response_types.to_d_ts

    expect(declaration).to include("  starts_at: Date;")
    expect(declaration).to include("  metadata?: Record<string, { value: number, label: string }>;")
  end

  it "rejects unsafe raw TypeScript expressions" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "Date;\nexport type Leak = string" } }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "rejects raw TypeScript expressions with line comments" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { values: { array: { raw: "string //" } } }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "rejects raw TypeScript expressions with ECMAScript line separators" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "Date\u2028export type Leak = string" } }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)

    response_types.reset!
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "Date\u2029export type Leak = string" } }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "rejects raw TypeScript expressions with unbalanced braces" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "string } export type Injected = any" } }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "rejects raw TypeScript expressions with top-level commas" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "string, injected: any" } }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "rejects raw TypeScript expressions with bare closing generic brackets" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: { raw: "> SomeType" } }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /single-line type expressions/)
  end

  it "requires scalar aliases to use documented lowercase symbols" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: { starts_at: :String }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /Unknown scalar response type alias: :String/)
  end

  it "reserves TypeScript globals commonly used in raw type specs" do
    %w[Array Date Promise ReadonlyArray Record].each do |type_name|
      expect do
        response_types.define_type(type_name, fields: {})
      end.to raise_error(ReactOnRails::Error, /reserved/)
    end
  end

  it "parenthesizes raw composite array members before appending array brackets" do
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: {
        project_ids: { array: { raw: "string & { __brand: 'ProjectId' }" } }
      }
    )

    expect(response_types.to_d_ts).to include("  project_ids: (string & { __brand: 'ProjectId' })[];")
  end

  it "parenthesizes raw function, conditional, and unary array members" do
    response_types.define_type("Project", fields: { id: :number, slug: :string })
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: {
        project_key: { array: { raw: "keyof Project" } },
        formatter: { array: { raw: "(value: Project) => string" } },
        labels: { array: { raw: "Project extends { id: number } ? string : number" } }
      }
    )

    declaration = response_types.to_d_ts

    expect(declaration).to include("  project_key: (keyof Project)[];")
    expect(declaration).to include("  formatter: ((value: Project) => string)[];")
    expect(declaration).to include("  labels: (Project extends { id: number } ? string : number)[];")
  end

  it "parenthesizes nullable raw function and conditional wrappers before adding null" do
    response_types.define_type("Project", fields: { id: :number, slug: :string })
    response_types.define_response(
      "events.show",
      type_name: "EventsShowResponse",
      fields: {
        formatter: { raw: "(value: Project) => string", nullable: true },
        label: { raw: "Project extends { id: number } ? string : number", nullable: true },
        labels: { array: { raw: "Project extends { id: number } ? string : number", nullable: true } }
      }
    )

    declaration = response_types.to_d_ts

    expect(declaration).to include("  formatter: ((value: Project) => string) | null;")
    expect(declaration).to include("  label: (Project extends { id: number } ? string : number) | null;")
    expect(declaration).to include("  labels: ((Project extends { id: number } ? string : number) | null)[];")
  end

  it "reports unknown option keys on wrapper-looking specs" do
    response_types.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        value: { type: :string, nullablee: true }
      }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /Unrecognized option key\(s\).*:nullablee/)
  end

  it "reports unknown option keys when modifiers are mixed with plain object fields" do
    response_types.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        value: { type: :string, nullable: true, hint: "legacy field" }
      }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /Unrecognized option key\(s\).*:hint/)
  end

  it "reports unknown option keys when multiple wrapper keys make the spec ambiguous" do
    response_types.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        value: { array: :string, fields: :json, typo: true }
      }
    )

    expect do
      response_types.to_d_ts
    end.to raise_error(ReactOnRails::Error, /Unrecognized option key\(s\).*:typo/)
  end

  it "preserves plain object fields when wrapper-like keys are paired with regular field names" do
    response_types.define_response(
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

    expect(response_types.to_d_ts).to include(expected_event_type)
  end

  it "preserves plain object fields whose names look like option-key typos" do
    response_types.define_response(
      "payload.show",
      type_name: "PayloadShowResponse",
      fields: {
        event: { type: :string, types: :string, rawness: :boolean }
      }
    )

    expected_event_type = [
      "  event: {",
      "    type: string;",
      "    types: string;",
      "    rawness: boolean;",
      "  };"
    ].join("\n")

    expect(response_types.to_d_ts).to include(expected_event_type)
  end

  it "omits keyed response helpers when no responses are registered" do
    response_types.define_type("Project", fields: { id: :number })

    declaration = response_types.to_d_ts

    expect(declaration).to include("export interface Project")
    expect(declaration).to include("export interface RailsResponseTypes {}")
    expect(declaration).not_to include("export type RailsResponseTypeName")
    expect(declaration).not_to include("export type RailsResponseType<")
  end

  it "trims response keys before storing them" do
    response_types.define_response(" projects.index ", type_name: "ProjectsIndexResponse", fields: {})

    declaration = response_types.to_d_ts

    expect(declaration).to include('  "projects.index": ProjectsIndexResponse;')
    expect(declaration).not_to include('" projects.index "')
  end
end
