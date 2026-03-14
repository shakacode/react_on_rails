# frozen_string_literal: true

shared_examples "pro_common_files" do
  it "creates Pro initializer with NodeRenderer configuration" do
    assert_file "config/initializers/react_on_rails_pro.rb" do |content|
      expect(content).to include("ReactOnRailsPro.configure")
      expect(content).to include('config.server_renderer = "NodeRenderer"')
    end
  end

  it "creates node-renderer.js bootstrap file" do
    assert_file "client/node-renderer.js" do |content|
      expect(content).to include("reactOnRailsProNodeRenderer")
    end
  end

  it "adds node-renderer process to Procfile.dev" do
    assert_file "Procfile.dev" do |content|
      expect(content).to include("node-renderer:")
      expect(content).to include("RENDERER_PORT=3800")
    end
  end
end
