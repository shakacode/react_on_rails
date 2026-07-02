# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  RSpec.describe TypeScriptResponseTypes, "emitter snapshots" do
    before { described_class.reset! }

    after { described_class.reset! }

    it "snapshots registry definitions once per emission regardless of custom type references" do
      described_class.define_type("Project", fields: { id: :number })
      described_class.define_type("Owner", fields: { id: :number, project: "Project" })
      described_class.define_response(
        "projects.index",
        type_name: "ProjectsIndexResponse",
        fields: {
          projects: { array: "Project" },
          owner: "Owner",
          featured: {
            fields: {
              project: "Project",
              owner: "Owner"
            }
          }
        }
      )

      registry = described_class.registry
      expect(registry).to receive(:types).once.and_call_original
      expect(registry).to receive(:responses).once.and_call_original

      declaration = described_class.to_d_ts

      expect(declaration).to include("projects: Project[];")
      expect(declaration).to include("owner: Owner;")
    end
  end
end
