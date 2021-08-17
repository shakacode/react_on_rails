# frozen_string_literal: true

require "rails_helper"

def change_text_expect_dom_selector(dom_selector)
  new_text = "John Doe"

  within(dom_selector) do
    find("input").set new_text
    within("h3") do
      expect(subject).to have_content new_text
    end
  end
end

def wait_for_ajax
  Timeout.timeout(Capybara.default_max_wait_time) do
    loop until finished_all_ajax_requests?
  end
end

def finished_all_ajax_requests?
  page.evaluate_script("jQuery.active").zero?
end

shared_examples "React Component" do |dom_selector|
  scenario { is_expected.to have_css dom_selector }

  scenario "changes name in message according to input" do
    change_text_expect_dom_selector(dom_selector)
  end
end

describe "Pages/Index", :js do
  subject { page }

  context "when rendering All in one page" do
    before do
      visit root_path
    end

    context "with Server Rendered/Cached React/Redux Component" do
      include_examples "React Component", "div#ReduxApp-react-component-0"
    end

    context "with Server Rendered/Cached React Component Without Redux" do
      include_examples "React Component", "div#HelloWorld-react-component-1"
    end

    context "with Simple Client Rendered Component" do
      include_examples "React Component", "div#HelloWorldApp-react-component-2"

      context "with same component with different props" do
        include_examples "React Component", "div#HelloWorldApp-react-component-3"
      end
    end

    context "with Simple Component Without Redux" do
      include_examples "React Component", "div#HelloWorld-react-component-5"
      include_examples "React Component", "div#HelloWorldES5-react-component-5"
    end

    context "with Non-React Component" do
      it { is_expected.to have_content "Time to visit Maui" }
    end

    context "when rendering React Hooks" do
      context "with Simple stateless component" do
        include_examples "React Component", "div#HelloWorld-react-component-6"
      end

      context "with Render-Function that takes props" do
        include_examples "React Component", "div#HelloWorld-react-component-7"
      end
    end
  end
end

context "when Server Rendering with Options", :js do
  subject { page }

  before do
    visit server_side_hello_world_with_options_path
  end

  include_examples "React Component", "div#my-hello-world-id"
end

describe "Turbolinks across pages", :js do
  subject { page }

  it "changes name in message according to input" do
    visit "/client_side_hello_world"
    change_text_expect_dom_selector("#HelloWorld-react-component-0")
    click_link "Hello World Component Server Rendered, with extra options"
    change_text_expect_dom_selector("#my-hello-world-id")
  end
end

describe "Pages/client_side_log_throw", :js, :ignore_js_errors do
  subject { page }

  before { visit "/client_side_log_throw" }

  it "client side logging and error handling", :js do
    expect(page).to have_text "This example demonstrates client side logging and error handling."
  end
end

describe "Pages/Pure Component", :js do
  subject { page }

  before { visit "/pure_component" }

  it { is_expected.to have_text "This is a Pure Component!" }
end

describe "Pages/server_side_log_throw", :js, :ignore_js_errors do
  subject { page }

  before { visit "/server_side_log_throw" }

  it "page has server side throw messages", :js do
    expect(page).to have_text "This example demonstrates server side logging and error handling."
    expect(page).to have_text "Exception in rendering!\n\nMessage: throw in HelloWorldWithLogAndThrow"
  end
end

describe "Pages/server_side_log_throw_raise", :js do
  subject { page }

  before { visit "/server_side_log_throw_raise" }

  it "redirects to /client_side_hello_world and flashes an error" do
    flash_message = page.find(:css, ".flash").text
    expect(flash_message).to eq("Error prerendering in react_on_rails. Redirected back to"\
                                " '/server_side_log_throw_raise_invoker'. See server logs for output.")
    expect(page).to have_current_path("/server_side_log_throw_raise_invoker")
  end
end

describe "Pages/index after using browser's back button", :js do
  subject { page }

  before do
    visit root_path
    visit "/client_side_hello_world"
    go_back
  end

  include_examples "React Component", "div#ReduxApp-react-component-0"
end

describe "React Router", :js do
  subject { page }

  before do
    visit "/"
    click_link "React Router"
  end

  context "when rendering /react_router" do
    it { is_expected.to have_text("Woohoo, we can use react-router here!") }

    it "clicking links correctly renders other pages" do
      click_link "Router First Page"
      expect(page).to have_current_path("/react_router/first_page")
      first_page_header_text = page.find(:css, "h2#first-page").text
      expect(first_page_header_text).to eq("React Router First Page")

      click_link "Router Second Page"
      expect(page).to have_current_path("/react_router/second_page")
      second_page_header_text = page.find(:css, "h2#second-page").text
      expect(second_page_header_text).to eq("React Router Second Page")
    end
  end
end

describe "Manual Rendering", :js, type: :system do
  subject { page }

  before { visit "/client_side_manual_render" }

  it "renderer function is called successfully" do
    header_text = page.find(:css, "h1#manual-render").text
    expect(header_text).to eq("Manual Render Example")
    expect(page).to have_text "If you can see this, you can register renderer functions."
  end
end

describe "renderedHtml from generator function", :js do
  subject { page }

  before { visit "/rendered_html" }

  it "renderedHtml should not have any errors" do
    expect(page).to have_text 'Props: {"hello":"world"}'
    expect(page.html).to include("[SERVER] RENDERED RenderedHtml to dom node with id")
  end
end

describe "Manual client hydration", :js, type: :system do
  before { visit "/xhr_refresh" }

  it "HelloWorldRehydratable onChange should trigger" do
    within("form") do
      click_button "refresh"
    end
    wait_for_ajax
    within("#HelloWorldRehydratable-react-component-1") do
      find("input").set "Should update"
      within("h3") do
        expect(page).to have_content "Should update"
      end
    end
  end
end

describe "returns hash if hash_result == true even with prerendering error", :js, :ignore_js_errors do
  subject { page }

  before do
    visit "/broken_app"
  # rubocop:disable Lint/SuppressedException
  rescue Selenium::WebDriver::Error::JavascriptError
  end
  # rubocop:enable Lint/SuppressedException

  it "react_component should return hash" do
    expect(page.html).to include("Exception in rendering!")
  end
end

describe "generator function returns renderedHtml as an object with additional HTML markups" do
  shared_examples "renderedHtmls should not have any errors and set correct page title" do
    subject { page }

    before { visit react_helmet_path }

    it "renderedHtmls should not have any errors" do
      expect(page).to have_text 'Props: {"helloWorldData":{"name":"Mr. Server Side Rendering"}}'
      expect(page).to have_css "title", text: /\ACustom page title\z/, visible: :hidden
      expect(page.html).to include("[SERVER] RENDERED ReactHelmetApp to dom node with id")
    end
  end

  describe "with disabled JS", :rack_test do
    include_examples "renderedHtmls should not have any errors and set correct page title"
  end

  describe "with enabled JS", :js do
    include_examples "renderedHtmls should not have any errors and set correct page title"
    it "renders the name change" do
      change_text_expect_dom_selector("div#react-helmet-0")
    end
  end
end

describe "display images", :js do
  subject { page }

  before { visit "/image_example" }

  it "image_example should not have any errors" do
    expect(page).to have_text "Here is a label with a background-image from the CSS modules imported"
    expect(page.html).to include("[SERVER] RENDERED ImageExample to dom node with id")
  end
end

shared_examples "React Component Shared Store" do |url|
  subject { page }

  before { visit url }

  context url do
    scenario "Type in one component changes the other component" do
      expect(page).to have_current_path(url, ignore_query: true)
      new_text = "John Doe"
      new_text2 = "Jane Smith"
      within("#ReduxSharedStoreApp-react-component-0") do
        find("input").set new_text
        within("h3") do
          expect(page).to have_content new_text
        end
      end
      within("#ReduxSharedStoreApp-react-component-1") do
        within("h3") do
          expect(page).to have_content new_text
        end
        find("input").set new_text2
      end
      within("#ReduxSharedStoreApp-react-component-0") do
        within("h3") do
          expect(page).to have_content new_text2
        end
      end
    end
  end
end

describe "2 react components, 1 store, client only", :js do
  include_examples "React Component Shared Store", "/client_side_hello_world_shared_store"
end

describe "2 react components, 1 store, server side", :js do
  include_examples "React Component Shared Store", "/server_side_hello_world_shared_store"
end

describe "2 react components, 1 store, client only, controller setup", :js do
  include_examples "React Component Shared Store", "/client_side_hello_world_shared_store_controller"
end

describe "2 react components, 1 store, server side, controller setup", :js do
  include_examples "React Component Shared Store", "/server_side_hello_world_shared_store_controller"
end

describe "2 react components, 1 store, client only, defer", :js do
  include_examples "React Component Shared Store", "/client_side_hello_world_shared_store_defer"
end

describe "2 react components, 1 store, server side, defer", :js do
  include_examples "React Component Shared Store", "/server_side_hello_world_shared_store_defer"
end
