# frozen_string_literal: true

require_relative "spec_helper"

module ReactOnRails
  describe SmartError do
    describe "#initialize and #message" do
      context "with component_not_registered error" do
        subject(:error) do
          described_class.new(
            error_type: :component_not_registered,
            component_name: "ProductCard",
            available_components: %w[ProductList ProductDetails UserProfile]
          )
        end

        it "creates error with helpful message" do
          message = error.message
          expect(message).to include("Component 'ProductCard' Not Registered")
          expect(message).to include("ReactOnRails.register({ ProductCard: ProductCard })")
          expect(message).to include("import ProductCard from './components/ProductCard'")
        end

        it "suggests similar components" do
          message = error.message
          expect(message).to include("ProductList")
          expect(message).to include("ProductDetails")
        end

        it "includes troubleshooting section" do
          message = error.message
          expect(message).to include("Get Help & Support")
        end
      end

      context "with missing_auto_loaded_bundle error" do
        subject(:error) do
          described_class.new(
            error_type: :missing_auto_loaded_bundle,
            component_name: "Dashboard",
            expected_path: "/app/webpack/generated/Dashboard.js"
          )
        end

        it "provides bundle generation guidance" do
          message = error.message
          expect(message).to include("Auto-loaded Bundle Missing")
          expect(message).to include("bundle exec rake react_on_rails:generate_packs")
          expect(message).to include("/app/webpack/generated/Dashboard.js")
        end
      end

      context "with hydration_mismatch error" do
        subject(:error) do
          described_class.new(
            error_type: :hydration_mismatch,
            component_name: "UserProfile"
          )
        end

        it "provides hydration debugging tips" do
          message = error.message
          expect(message).to include("Hydration Mismatch")
          expect(message).to include("typeof window !== 'undefined'")
          expect(message).to include("prerender: false")
          expect(message).to include("Use consistent values between server and client")
        end
      end

      context "with server_rendering_error" do
        subject(:error) do
          described_class.new(
            error_type: :server_rendering_error,
            component_name: "ComplexComponent",
            error_message: "window is not defined"
          )
        end

        it "provides server rendering troubleshooting" do
          message = error.message
          expect(message).to include("Server Rendering Failed")
          expect(message).to include("window is not defined")
          expect(message).to include("config.trace = true")
          expect(message).to include("bin/shakapacker")
        end
      end

      context "with redux_store_not_found error" do
        subject(:error) do
          described_class.new(
            error_type: :redux_store_not_found,
            store_name: "AppStore",
            available_stores: %w[UserStore ProductStore]
          )
        end

        it "provides store registration help" do
          message = error.message
          expect(message).to include("Redux Store Not Found")
          expect(message).to include("ReactOnRails.registerStore({ AppStore: AppStore })")
          expect(message).to include("UserStore, ProductStore")
        end
      end
    end

    describe "#solution" do
      it "returns appropriate solution for each error type" do
        errors = [
          { type: :component_not_registered, component: "Test" },
          { type: :missing_auto_loaded_bundle, component: "Test" },
          { type: :hydration_mismatch, component: "Test" },
          { type: :server_rendering_error, component: "Test" },
          { type: :redux_store_not_found, store_name: "TestStore" },
          { type: :configuration_error, details: "Invalid path" }
        ]

        errors.each do |error_info|
          error = described_class.new(
            error_type: error_info[:type],
            component_name: error_info[:component],
            store_name: error_info[:store_name],
            details: error_info[:details]
          )
          expect(error.solution).not_to be_empty
          expect(error.solution).to be_a(String)
        end
      end
    end

    describe "component name suggestions" do
      subject(:error) do
        described_class.new(
          error_type: :component_not_registered,
          component_name: "helloworld",
          available_components: %w[HelloWorld HelloWorldApp Header]
        )
      end

      it "suggests properly capitalized component names" do
        message = error.message
        expect(message).to include("HelloWorld")
      end
    end

    describe "colored output" do
      subject(:error) do
        described_class.new(
          error_type: :component_not_registered,
          component_name: "TestComponent"
        )
      end

      it "includes colored output markers" do
        # Enable Rainbow coloring for this test
        Rainbow.enabled = true
        message = error.message
        # Rainbow adds ANSI color codes
        expect(message).to match(/\e\[/) # ANSI escape sequence
      ensure
        Rainbow.enabled = false
      end
    end

    describe "context information" do
      subject(:error) do
        described_class.new(
          error_type: :component_not_registered,
          component_name: "TestComponent",
          available_components: %w[Component1 Component2]
        )
      end

      it "includes Rails environment context" do
        message = error.message
        expect(message).to include("Context:")
        expect(message).to include("Component:")
      end

      it "shows registered components when available" do
        message = error.message
        expect(message).to include("Component1, Component2")
      end
    end
  end
end
