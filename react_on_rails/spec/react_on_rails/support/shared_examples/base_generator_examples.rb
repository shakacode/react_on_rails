# frozen_string_literal: true

shared_examples "base_generator_common" do |options = {}|
  tailwind = options.fetch(:tailwind, false)
  it "adds a route for get 'hello_world' to 'hello_world#index'" do
    match = <<~MATCH
      Rails.application.routes.draw do
        get 'hello_world', to: 'hello_world#index'
      end
    MATCH
    assert_file "config/routes.rb", match
  end

  it "copies common files" do
    %w[app/controllers/hello_world_controller.rb
       app/views/layouts/react_on_rails_default.html.erb
       config/initializers/react_on_rails.rb
       Procfile.dev
       Procfile.dev-static-assets
       Procfile.dev-prod-assets
       .env.example].each { |file| assert_file(file) }
  end

  it "uses env-var-driven port in Procfile.dev" do
    assert_file "Procfile.dev", /\$\{PORT:-3000\}/
  end

  it "uses env-var-driven port in Procfile.dev-static-assets" do
    assert_file "Procfile.dev-static-assets", /\$\{PORT:-3000\}/
  end

  it "uses env-var-driven port in Procfile.dev-prod-assets" do
    assert_file "Procfile.dev-prod-assets", /\$\{PORT:-3001\}/
  end

  it "creates react_on_rails_default layout with a polished head and pack tags" do
    assert_file "app/views/layouts/react_on_rails_default.html.erb" do |content|
      expect(content).to include("<title>React on Rails</title>")
      expect(content).to include('<meta name="viewport" content="width=device-width,initial-scale=1">')
      expect(content).to include("<%= csrf_meta_tags %>")
      expect(content).to include("<%= csp_meta_tag %>")
      expect(content).to include("<%= javascript_pack_tag %>")

      if tailwind
        prepend_index = content.index('<% prepend_javascript_pack_tag "react_on_rails_tailwind" %>')
        stylesheet_index = content.index('<%= stylesheet_pack_tag "react_on_rails_tailwind", media: "all" %>')
        javascript_index = content.index("<%= javascript_pack_tag %>")

        expect(prepend_index).not_to be_nil
        expect(stylesheet_index).not_to be_nil
        expect(prepend_index).to be < stylesheet_index
        expect(stylesheet_index).to be < javascript_index
        expect(content).not_to include("<%= stylesheet_pack_tag %>")
      else
        expect(content).to include("<%= stylesheet_pack_tag %>")
        expect(content).not_to include("react_on_rails_tailwind")
      end
    end
  end

  it "creates HelloWorld controller with react_on_rails_default layout" do
    assert_file "app/controllers/hello_world_controller.rb" do |content|
      expect(content).to include('layout "react_on_rails_default"')
    end
  end
end

shared_examples "react_component_structure" do
  it "creates react directories" do
    # Auto-registration structure for non-Redux components
    assert_directory "app/javascript/src/HelloWorld/ror_components"
  end

  it "copies react files" do
    # Auto-registration components for non-Redux
    assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.client.jsx"
    assert_file "app/javascript/src/HelloWorld/ror_components/HelloWorld.server.jsx"
  end
end

shared_examples "base_generator" do
  include_examples "base_generator_common"
  include_examples "react_component_structure"
end
