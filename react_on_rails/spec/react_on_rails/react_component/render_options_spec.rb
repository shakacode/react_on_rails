# frozen_string_literal: true

require_relative "../spec_helper"

describe ReactOnRails::ReactComponent::RenderOptions do
  configurable_options = %i[
    prerender
    trace
    replay_console
    raise_on_prerender_error
    random_dom_id
  ].freeze

  def the_attrs(react_component_name: "App", options: {})
    {
      react_component_name:,
      options:
    }
  end

  # TODO: test pro features without license
  before do
    allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
  end

  def with_prerender_env_override_cleared
    original_prerender_override = ENV.fetch("REACT_ON_RAILS_PRERENDER_OVERRIDE", nil)
    ENV.delete("REACT_ON_RAILS_PRERENDER_OVERRIDE")
    described_class.reset_prerender_env_override_cache!
    yield
  ensure
    if original_prerender_override.nil?
      ENV.delete("REACT_ON_RAILS_PRERENDER_OVERRIDE")
    else
      ENV["REACT_ON_RAILS_PRERENDER_OVERRIDE"] = original_prerender_override
    end
    described_class.reset_prerender_env_override_cache!
  end

  it "works without raising error" do
    attrs = the_attrs

    expect do
      described_class.new(**attrs)
    end.not_to raise_error
  end

  describe "#props" do
    context "without props" do
      it "returns empty hash" do
        attrs = the_attrs

        opts = described_class.new(**attrs)

        expect(opts.props).to eq({})
      end
    end

    context "with props Hash" do
      it "returns props" do
        props = { a_prop: 2 }
        attrs = the_attrs(options: { props: })

        opts = described_class.new(**attrs)

        expect(opts.props).to eq(props)
      end
    end
  end

  describe "#react_component_name" do
    it "returns react_component_name with correct format" do
      react_component_name = "some_app"
      attrs = the_attrs(react_component_name:)

      opts = described_class.new(**attrs)

      expect(opts.react_component_name).to eq "SomeApp"
    end
  end

  describe "#dom_id" do
    context "without id option" do
      context "with random_dom_id set to true" do
        it "returns a unique identifier" do
          attrs = the_attrs(react_component_name: "SomeApp", options: { random_dom_id: true })
          opts = described_class.new(**attrs)

          allow(SecureRandom).to receive(:uuid).and_return("123456789")
          expect(SecureRandom).to receive(:uuid)
          expect(opts.dom_id).to eq "SomeApp-react-component-123456789"
          expect(opts.random_dom_id?).to be(true)
        end

        it "is memoized" do
          opts = described_class.new(**the_attrs)
          generated_value = opts.dom_id

          expect(opts.instance_variable_get(:@dom_id)).to eq generated_value
          expect(opts.instance_variable_get(:@dom_id)).to eq opts.dom_id

          opts.instance_variable_set(:@dom_id, "1234")
          expect(opts.dom_id).to eq "1234"
        end
      end

      context "with random_dom_id set to false" do
        it "returns a default identifier" do
          attrs = the_attrs(react_component_name: "SomeApp", options: { random_dom_id: false })
          opts = described_class.new(**attrs)
          expect(opts.dom_id).to eq "SomeApp-react-component"
          expect(opts.random_dom_id?).to be(false)
        end
      end
    end

    context "with id option" do
      it "returns given id" do
        options = { id: "im-an-id" }
        attrs = the_attrs(options:)

        opts = described_class.new(**attrs)

        expect(opts.dom_id).to eq "im-an-id"
        expect(opts.random_dom_id?).to be(false)
      end
    end
  end

  describe "#html_options" do
    context "without html_options" do
      it "returns empty hash" do
        attrs = the_attrs

        opts = described_class.new(**attrs)

        expect(opts.html_options).to eq({})
      end
    end

    context "with html_options" do
      it "returns html options" do
        html_options = { id: 2 }
        options = { html_options: }
        attrs = the_attrs(options:)

        opts = described_class.new(**attrs)

        expect(opts.html_options).to eq html_options
      end
    end
  end

  describe "#hydrate_on" do
    it "defaults to immediate and is not explicit" do
      opts = described_class.new(**the_attrs)

      expect(opts.hydrate_on).to eq(:immediate)
    end

    it "treats nil as the default immediate mode" do
      opts = described_class.new(**the_attrs(options: { hydrate_on: nil }))

      expect(opts.hydrate_on).to eq(:immediate)
    end

    context "without React on Rails Pro" do
      before do
        allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(false)
      end

      it "accepts supported symbol modes" do
        %i[immediate visible idle].each do |hydrate_on|
          opts = described_class.new(**the_attrs(options: { hydrate_on: }))

          expect(opts.hydrate_on).to eq(hydrate_on)
        end
      end

      it "normalizes supported string modes" do
        opts = described_class.new(**the_attrs(options: { hydrate_on: "visible" }))

        expect(opts.hydrate_on).to eq(:visible)
      end
    end

    it "rejects unsupported modes" do
      expect do
        described_class.new(**the_attrs(options: { hydrate_on: :interaction }))
      end.to raise_error(ArgumentError, /Supported OSS modes are :immediate, :visible, and :idle/)
    end

    it "rejects deferred modes when React on Rails Pro is installed" do
      allow(ReactOnRails::Utils).to receive(:react_on_rails_pro?).and_return(true)
      expect do
        described_class.new(**the_attrs(options: { hydrate_on: :visible }))
      end.to raise_error(ArgumentError, /React on Rails Pro does not support hydrate_on scheduling/)
    end
  end

  describe "#prerender env override" do
    around do |example|
      original_prerender_config = ReactOnRails.configuration.prerender
      with_prerender_env_override_cleared { example.run }
    ensure
      ReactOnRails.configuration.prerender = original_prerender_config
    end

    it "overrides explicit option when env is true" do
      ENV["REACT_ON_RAILS_PRERENDER_OVERRIDE"] = "true"
      attrs = the_attrs(options: { prerender: false })
      opts = described_class.new(**attrs)

      expect(opts.prerender).to be true
    end

    it "overrides explicit option when env is false" do
      ENV["REACT_ON_RAILS_PRERENDER_OVERRIDE"] = "false"
      attrs = the_attrs(options: { prerender: true })
      opts = described_class.new(**attrs)

      expect(opts.prerender).to be false
    end

    it "overrides config default when env is false and no explicit option is set" do
      ENV["REACT_ON_RAILS_PRERENDER_OVERRIDE"] = "false"
      ReactOnRails.configuration.prerender = true
      attrs = the_attrs
      opts = described_class.new(**attrs)

      expect(opts.prerender).to be false
    end

    it "normalizes env values with case and whitespace" do
      ENV["REACT_ON_RAILS_PRERENDER_OVERRIDE"] = " TRUE "
      attrs = the_attrs(options: { prerender: false })
      opts = described_class.new(**attrs)

      expect(opts.prerender).to be true
    end

    it "falls back to configured behavior for invalid env values" do
      ENV["REACT_ON_RAILS_PRERENDER_OVERRIDE"] = "definitely-not-boolean"
      ReactOnRails.configuration.prerender = true

      expect(Rails.logger).to receive(:warn)
        .with(/Ignoring REACT_ON_RAILS_PRERENDER_OVERRIDE/)
        .once

      attrs = the_attrs
      opts = described_class.new(**attrs)

      expect(opts.prerender).to be true
      expect(opts.prerender).to be true
    end

    it "uses configured precedence when env var is absent" do
      ReactOnRails.configuration.prerender = false
      attrs = the_attrs(options: { prerender: true })
      opts = described_class.new(**attrs)

      expect(opts.prerender).to be true
    end
  end

  configurable_options.each do |option|
    describe "##{option}" do
      context "with #{option} option" do
        it "returns #{option}" do
          options = {}
          options[option] = false
          attrs = the_attrs(options:)
          if option == :prerender
            with_prerender_env_override_cleared do
              opts = described_class.new(**attrs)
              expect(opts.public_send(option)).to be false
            end
          else
            opts = described_class.new(**attrs)
            expect(opts.public_send(option)).to be false
          end
        end
      end

      context "without #{option} option" do
        it "returns #{option} from config" do
          ReactOnRails.configuration.public_send(:"#{option}=", true)
          attrs = the_attrs
          if option == :prerender
            with_prerender_env_override_cleared do
              opts = described_class.new(**attrs)
              expect(opts.public_send(option)).to be true
            end
          else
            opts = described_class.new(**attrs)
            expect(opts.public_send(option)).to be true
          end
        end
      end
    end
  end
end
