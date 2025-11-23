# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "Gemspec file inclusion" do
  describe "react_on_rails.gemspec" do
    let(:gemspec_path) { File.expand_path("../../react_on_rails.gemspec", __dir__) }
    let(:gemspec) { Gem::Specification.load(gemspec_path) }

    it "exists and is valid" do
      expect(gemspec).not_to be_nil
      expect(gemspec.name).to eq("react_on_rails")
    end

    context "when checking Pro file exclusion" do
      it "does not include any files from lib/react_on_rails_pro/" do
        pro_lib_files = gemspec.files.select { |f| f.start_with?("lib/react_on_rails_pro") }
        expect(pro_lib_files).to be_empty,
                                  "MIT gem should not include Pro lib files, but found: #{pro_lib_files.join(', ')}"
      end

      it "does not include any files from react_on_rails_pro/ directory" do
        pro_dir_files = gemspec.files.select { |f| f.start_with?("react_on_rails_pro/") }
        expect(pro_dir_files).to be_empty,
                                  "MIT gem should not include Pro directory files, " \
                                  "but found: #{pro_dir_files.join(', ')}"
      end

      it "does not include Pro-specific rake tasks" do
        pro_rake_tasks = gemspec.files.grep(%r{^lib/tasks/(assets_pro|v8_log_processor)\.rake$})
        expect(pro_rake_tasks).to be_empty,
                                   "MIT gem should not include Pro rake tasks, but found: #{pro_rake_tasks.join(', ')}"
      end

      it "does not include Pro gemspec file" do
        pro_gemspec = gemspec.files.select { |f| f == "react_on_rails_pro.gemspec" }
        expect(pro_gemspec).to be_empty,
                               "MIT gem should not include Pro gemspec"
      end

      it "does not include CHANGELOG_PRO.md" do
        pro_changelog = gemspec.files.select { |f| f == "CHANGELOG_PRO.md" }
        expect(pro_changelog).to be_empty,
                                 "MIT gem should not include Pro changelog"
      end

      it "does not include spec/pro/ test files" do
        pro_specs = gemspec.files.select { |f| f.start_with?("spec/pro/") }
        expect(pro_specs).to be_empty,
                             "MIT gem should not include Pro spec files, but found: #{pro_specs.join(', ')}"
      end
    end

    context "when checking MIT file inclusion" do
      it "includes lib/react_on_rails.rb" do
        expect(gemspec.files).to include("lib/react_on_rails.rb")
      end

      it "includes files from lib/react_on_rails/ directory" do
        ror_files = gemspec.files.select { |f| f.start_with?("lib/react_on_rails/") }
        expect(ror_files).not_to be_empty
      end

      it "includes standard MIT rake tasks" do
        rake_tasks = gemspec.files.grep(%r{^lib/tasks/.*\.rake$})
        # Should include standard tasks but not Pro tasks
        expect(rake_tasks).not_to be_empty
        expect(rake_tasks).to all(satisfy { |f| !f.match?(/assets_pro|v8_log_processor/) })
      end
    end
  end

  describe "react_on_rails_pro.gemspec" do
    let(:gemspec_path) { File.expand_path("../../react_on_rails_pro.gemspec", __dir__) }
    let(:gemspec) do
      # The Pro gemspec requires the version files, so we need to allow that
      Gem::Specification.load(gemspec_path)
    end

    it "exists and is valid" do
      expect(gemspec).not_to be_nil
      expect(gemspec.name).to eq("react_on_rails_pro")
    end

    context "when checking Pro file inclusion" do
      it "includes lib/react_on_rails_pro.rb main file" do
        expect(gemspec.files).to include("lib/react_on_rails_pro.rb")
      end

      it "includes all files from lib/react_on_rails_pro/ directory" do
        # Get actual files in the directory
        actual_pro_files = Dir.glob("lib/react_on_rails_pro/**/*")
                              .reject { |f| File.directory?(f) }
                              .sort

        # Get files included in gemspec
        included_pro_files = gemspec.files.select { |f| f.start_with?("lib/react_on_rails_pro/") }
                                    .sort

        missing_files = actual_pro_files - included_pro_files

        expect(missing_files).to be_empty,
                                 "Pro gemspec is missing files: #{missing_files.join(', ')}"
      end

      it "includes Pro-specific rake tasks" do
        expect(gemspec.files).to include("lib/tasks/assets_pro.rake")
        expect(gemspec.files).to include("lib/tasks/v8_log_processor.rake")
      end

      it "includes CHANGELOG_PRO.md" do
        expect(gemspec.files).to include("CHANGELOG_PRO.md")
      end

      it "includes react_on_rails_pro.gemspec" do
        expect(gemspec.files).to include("react_on_rails_pro.gemspec")
      end
    end

    context "when checking file exclusions" do
      it "does not include test infrastructure from react_on_rails_pro/ directory" do
        # Should not include the dummy app or test infrastructure
        test_files = gemspec.files.select do |f|
          f.start_with?("react_on_rails_pro/") && !f.match?(%r{^react_on_rails_pro/(README|LICENSE|CHANGELOG)})
        end
        expect(test_files).to be_empty,
                              "Pro gem should not include test infrastructure, but found: #{test_files.join(', ')}"
      end

      it "does not include spec/pro/ files (they're test files, not library code)" do
        # NOTE: spec/pro/ contains the Pro *tests*, not the Pro library code
        # The Pro library code is in lib/react_on_rails_pro/
        spec_files = gemspec.files.select { |f| f.start_with?("spec/pro/") }
        expect(spec_files).to be_empty,
                              "Pro gem should not include spec files, but found: #{spec_files.join(', ')}"
      end

      it "does not include MIT-only files" do
        # Make sure we're not accidentally including the base gem's files
        mit_files = gemspec.files.select do |f|
          f.start_with?("lib/react_on_rails/") || f == "lib/react_on_rails.rb"
        end
        expect(mit_files).to be_empty,
                             "Pro gem should not include MIT gem files, but found: #{mit_files.join(', ')}"
      end
    end
  end
end
