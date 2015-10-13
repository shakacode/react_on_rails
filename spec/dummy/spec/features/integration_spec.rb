require "rails_helper"

shared_examples "React Component" do |dom_selector|
  scenario { is_expected.to have_css dom_selector }

  scenario "changes text" do
    new_text = "Hey there!"

    within(dom_selector) do
      find("input").set new_text
      within("h3") do
        is_expected.to have_content new_text
      end
    end
  end
end

feature "Pages/Index", js: true do
  subject { page }

  context "All in one page" do
    background do
      visit root_path
    end

    context "Server Rendered/Cached React/Redux Component" do
      include_examples "React Component", "div#ReduxApp-react-component-0"
    end

    context "Server Rendered/Cached React Component Without Redux" do
      include_examples "React Component", "div#HelloWorld-react-component-1"
    end

    context "Simple Client Rendered Component" do
      include_examples "React Component", "div#HelloWorldApp-react-component-2"

      context "same component with different props" do
        include_examples "React Component", "div#HelloWorldApp-react-component-3"
      end
    end

    context "Simple Component Without Redux" do
      include_examples "React Component", "div#HelloWorld-react-component-4"
      include_examples "React Component", "div#HelloWorldES5-react-component-5"
    end

    context "Non-React Component" do
      scenario { is_expected.to have_content "Time to visit Maui" }
    end
  end

  context "Server Rendering with Options" do
    background do
      visit server_side_hello_world_with_options_path
    end

    include_examples "React Component", "div#my-hello-world-id"
  end
end
