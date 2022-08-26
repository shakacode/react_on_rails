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
      react_component_name: react_component_name,
      options: options
    }
  end

  it "works" do
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
        attrs = the_attrs(options: { props: props })

        opts = described_class.new(**attrs)

        expect(opts.props).to eq(props)
      end
    end
  end

  describe "#react_component_name" do
    it "returns react_component_name with correct format" do
      react_component_name = "some_app"
      attrs = the_attrs(react_component_name: react_component_name)

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
          expect(opts.random_dom_id?).to eq(true)
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
          expect(opts.random_dom_id?).to eq(false)
        end
      end
    end

    context "with id option" do
      it "returns given id" do
        options = { id: "im-an-id" }
        attrs = the_attrs(options: options)

        opts = described_class.new(**attrs)

        expect(opts.dom_id).to eq "im-an-id"
        expect(opts.random_dom_id?).to eq(false)
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
        options = { html_options: html_options }
        attrs = the_attrs(options: options)

        opts = described_class.new(**attrs)

        expect(opts.html_options).to eq html_options
      end
    end
  end

  configurable_options.each do |option|
    describe "##{option}" do
      context "with #{option} option" do
        it "returns #{option}" do
          options = {}
          options[option] = false
          attrs = the_attrs(options: options)

          opts = described_class.new(**attrs)

          expect(opts.public_send(option)).to be false
        end
      end

      context "without #{option} option" do
        it "returns #{option} from config" do
          ReactOnRails.configuration.public_send("#{option}=", true)
          attrs = the_attrs

          opts = described_class.new(**attrs)

          expect(opts.public_send(option)).to be true
        end
      end
    end
  end
end
