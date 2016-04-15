require_relative "../spec_helper"

describe ReactOnRails::ReactComponent::Options do
  CONFIGURABLE_OPTIONS = %i(
    prerender
    trace
    replay_console
    raise_on_prerender_error
  ).freeze

  def the_attrs(name: "App", index: 1, options: {})
    {
      name: name,
      index: index,
      options: options
    }
  end

  it "works" do
    attrs = the_attrs

    expect do
      described_class.new(attrs)
    end.not_to raise_error
  end

  describe "#props" do
    context "no props" do
      it "returns empty hash" do
        attrs = the_attrs

        opts = described_class.new(attrs)

        expect(opts.props).to eq({})
      end
    end

    context "as Hash" do
      it "returns props" do
        props = { a_prop: 2 }
        attrs = the_attrs(options: { props: props })

        opts = described_class.new(attrs)

        expect(opts.props).to eq(props)
      end
    end

    context "as JSON" do
      it "returns props" do
        json_props = { a_prop: 2 }.to_json
        attrs = the_attrs(options: { props: json_props })

        opts = described_class.new(attrs)

        expect(opts.props).to eq(json_props)
      end
    end
  end

  describe "#name" do
    it "returns name with correct format" do
      name = "some_app"
      attrs = the_attrs(name: name)

      opts = described_class.new(attrs)

      expect(opts.name).to eq "SomeApp"
    end
  end

  describe "#index" do
    it "returns index" do
      index = 2
      attrs = the_attrs(index: index)

      opts = described_class.new(attrs)

      expect(opts.index).to eq index
    end
  end

  describe "#dom_id" do
    context "without id option" do
      it "returns dom_id" do
        index = 2
        name = "some_app"
        attrs = the_attrs(name: name, index: index)

        opts = described_class.new(attrs)

        expect(opts.dom_id).to eq "some_app-react-component-2"
      end
    end

    context "with id option" do
      it "returns dom_id" do
        options = { id: "im-an-id" }
        attrs = the_attrs(options: options)

        opts = described_class.new(attrs)

        expect(opts.dom_id).to eq "im-an-id"
      end
    end
  end

  describe "#html_options" do
    context "without html_options" do
      it "returns empty hash" do
        attrs = the_attrs

        opts = described_class.new(attrs)

        expect(opts.html_options).to eq({})
      end
    end

    context "with html_options" do
      it "returns html options" do
        html_options = { id: 2 }
        options = { html_options: html_options }
        attrs = the_attrs(options: options)

        opts = described_class.new(attrs)

        expect(opts.html_options).to eq html_options
      end
    end
  end

  describe "#data" do
    it "returns data for component" do
      attrs = the_attrs(name: "app", options: { trace: false, id: 2 })
      expected_data = {
        component_name: "App",
        props: {},
        trace: false,
        dom_id: 2
      }

      opts = described_class.new(attrs)

      expect(opts.data).to eq expected_data
    end
  end

  describe "#style" do
    context "skipped display none" do
      it "returns nil" do
        ReactOnRails.configuration.skip_display_none = true
        attrs = the_attrs

        opts = described_class.new(attrs)

        expect(opts.style).to eq nil
      end
    end

    context "not skipped display none" do
      it "returns value" do
        ReactOnRails.configuration.skip_display_none = false
        attrs = the_attrs

        opts = described_class.new(attrs)

        expect(opts.style).to eq "display:none"
      end
    end
  end

  CONFIGURABLE_OPTIONS.each do |option|
    describe "##{option}" do
      context "with #{option} option" do
        it "returns #{option}" do
          options = {}
          options[option] = false
          attrs = the_attrs(options: options)

          opts = described_class.new(attrs)

          expect(opts.public_send(option)).to be false
        end
      end

      context "without #{option} option" do
        it "returns #{option} from config" do
          ReactOnRails.configuration.public_send("#{option}=", true)
          attrs = the_attrs

          opts = described_class.new(attrs)

          expect(opts.public_send(option)).to be true
        end
      end
    end
  end
end
