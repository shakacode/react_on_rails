# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe TypeScriptResponseTypes, "rendering" do
    before { described_class.reset! }

    after { described_class.reset! }

    it "escapes ECMAScript line separators in quoted property names" do
      line_separator = "\u2028"
      paragraph_separator = "\u2029"
      described_class.define_response(
        "events#{line_separator}show",
        type_name: "EventsShowResponse",
        fields: {
          "line#{line_separator}name" => :string,
          "paragraph#{paragraph_separator}name" => :number
        }
      )

      declaration = described_class.to_d_ts

      expect(declaration).to include('  "line\u2028name": string;')
      expect(declaration).to include('  "paragraph\u2029name": number;')
      expect(declaration).to include('  "events\u2028show": EventsShowResponse;')
      expect(declaration).not_to include(line_separator)
      expect(declaration).not_to include(paragraph_separator)
    end

    it "renders documented array shorthand specs" do
      described_class.define_type("Project", fields: { id: :number })
      described_class.define_response(
        "payload.show",
        type_name: "PayloadShowResponse",
        fields: {
          ids: [:number],
          tags: [:string],
          projects: ["Project"]
        }
      )

      declaration = described_class.to_d_ts

      expect(declaration).to include("  ids: number[];")
      expect(declaration).to include("  tags: string[];")
      expect(declaration).to include("  projects: Project[];")
    end

    it "renders empty registered contracts as strict empty object aliases" do
      described_class.define_type("EmptyMetadata", fields: {})
      described_class.define_response(
        "empty.show",
        type_name: "EmptyShowResponse",
        fields: { metadata: { fields: {} } }
      )

      declaration = described_class.to_d_ts

      expect(declaration).to include("export type EmptyMetadata = Record<string, never>;")
      expect(declaration).to include("export interface EmptyShowResponse")
      expect(declaration).to include("  metadata: Record<string, never>;")
      expect(declaration).to include('  "empty.show": EmptyShowResponse;')
      expect(declaration).not_to include("export interface EmptyMetadata {}")
      expect(declaration).not_to include("metadata: {};")
    end
  end
end
