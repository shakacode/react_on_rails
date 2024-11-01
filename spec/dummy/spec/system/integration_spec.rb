# frozen_string_literal: true

require "rails_helper"

def change_text_expect_dom_selector(dom_selector, expect_no_change: false)
  new_text = "John Doe"

  within(dom_selector) do
    find("input").set new_text
    within("h3") do
      if expect_no_change
        expect(subject).not_to have_content new_text
      else
        expect(subject).to have_content new_text
      end
    end
  end
end

shared_examples "React Component" do |dom_selector|
  it { is_expected.to have_css dom_selector }

  it "changes name in message according to input" do
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

context "when Server Rendering Cached", :caching, :js do
  subject { page }

  let(:dependencies_cache_key) { ReactOnRailsPro::Cache.dependencies_cache_key }
  let(:base_component_cache_key) { "ror_component/#{ReactOnRails::VERSION}/#{ReactOnRailsPro::VERSION}" }

  before do
    visit cached_redux_component_path
  end

  include_examples "React Component", "div#ReduxApp-react-component-0"

  # TODO: Fix this test
  # RSpec tests are running on external server now, so cache keys are stored in another ruby process
  # it "adds a value to the cache" do
  #   base_cache_key_with_prerender = "#{base_component_cache_key}/" \
  #                                   "#{ReactOnRailsPro::Utils.bundle_hash}/#{dependencies_cache_key}"
  #   expect(cache_data.keys[0]).to match(%r{#{base_cache_key_with_prerender}/ReduxApp})
  # end
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

describe "Pages/client_side_log_throw", :js do
  subject { page }

  before { visit "/client_side_log_throw" }

  it "demonstrates client side logging and error handling" do
    expect(page).to have_text "This example demonstrates client side logging and error handling."
  end
end

describe "Pages/stream_async_components_for_testing", :js do
  subject { page }

  it "renders the component" do
    visit "/stream_async_components_for_testing"
    expect(page).to have_text "Header for AsyncComponentsTreeForTesting"
    expect(page).to have_text "Footer for AsyncComponentsTreeForTesting"
  end

  it "hydrates the component" do
    visit "/stream_async_components_for_testing"
    expect(page.html).to include("client-bundle.js")
    change_text_expect_dom_selector("#AsyncComponentsTreeForTesting-react-component-0")
  end

  it "renders the page completely on server and displays content on client even without JavaScript" do
    # Don't add client-bundle.js to the page to ensure that the app is not hydrated
    visit "/stream_async_components_for_testing?skip_js_packs=true"
    expect(page.html).not_to include("client-bundle.js")
    # Ensure that the component state is not updated
    change_text_expect_dom_selector("#AsyncComponentsTreeForTesting-react-component-0", expect_no_change: true)

    expect(page).not_to have_text "Loading branch1"
    expect(page).not_to have_text "Loading branch2"
    expect(page).not_to have_text(/Loading branch1 at level \d+/)
    expect(page).to have_text(/branch1 \(level \d+\)/, count: 5)
  end

  shared_examples "shows loading fallback while rendering async components" do |skip_js_packs|
    it "shows the loading fallback while rendering async components" \
       "#{skip_js_packs ? ' when the page is not hydrated' : ''}" do
      path = "/stream_async_components_for_testing#{skip_js_packs ? '?skip_js_packs=true' : ''}"
      chunks_count = 0
      navigate_with_streaming(path) do |_content|
        chunks_count += 1
        expect(page).to have_text(/Loading branch1 at level \d+/, count: 1) if chunks_count < 5
        expect(page).to have_text(/Loading branch2 at level \d+/, count: 1) if chunks_count == 1
        expect(page).not_to have_text(/Loading branch2 at level \d+/) if chunks_count > 2
      end
      expect(page).not_to have_text(/Loading branch1 at level \d+/)
      expect(page).not_to have_text(/Loading branch2 at level \d+/)
      expect(chunks_count).to be >= 5

      # Check if the page is hydrated or not
      change_text_expect_dom_selector("#AsyncComponentsTreeForTesting-react-component-0",
                                      expect_no_change: skip_js_packs)
    end
  end

  it_behaves_like "shows loading fallback while rendering async components", false
  it_behaves_like "shows loading fallback while rendering async components", true

  it "replays console logs" do
    visit "/stream_async_components_for_testing"
    logs = page.driver.browser.logs.get(:browser)
    info = logs.select { |log| log.level == "INFO" }
    info_messages = info.map(&:message)
    errors = logs.select { |log| log.level == "SEVERE" }
    errors_messages = errors.map(&:message)

    expect(info_messages).to include(/\[SERVER\] Sync console log from AsyncComponentsTreeForTesting/)
    5.times do |i|
      expect(info_messages).to include(/\[SERVER\] branch1 \(level #{i}\)/)
      expect(errors_messages).to include(
        /"\[SERVER\] Error message" "{\\"branchName\\":\\"branch1\\",\\"level\\":#{i}}"/
      )
    end
    2.times do |i|
      expect(info_messages).to include(/\[SERVER\] branch2 \(level #{i}\)/)
      expect(errors_messages).to include(
        /"\[SERVER\] Error message" "{\\"branchName\\":\\"branch2\\",\\"level\\":#{i}}"/
      )
    end
  end

  it "replays console logs with each chunk" do
    chunks_count = 0
    navigate_with_streaming("/stream_async_components_for_testing") do |content|
      chunks_count += 1
      logs = page.driver.browser.logs.get(:browser)
      info = logs.select { |log| log.level == "INFO" }
      info_messages = info.map(&:message)
      errors = logs.select { |log| log.level == "SEVERE" }
      errors_messages = errors.map(&:message)

      next if content.empty? || chunks_count == 1

      expect(info_messages).to include(/\[SERVER\] branch1 \(level \d+\)/)
      expect(errors_messages).to include(
        /"\[SERVER\] Error message" "{\\"branchName\\":\\"branch1\\",\\"level\\":\d+}/
      )
    end
    expect(chunks_count).to be >= 5
  end
end

describe "Pages/Pure Component", :js do
  subject { page }

  before { visit "/pure_component" }

  it { is_expected.to have_text "This is a Pure Component!" }
end

describe "Pages/server_side_log_throw", :js do
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
    expect(flash_message).to eq("Error prerendering in react_on_rails. Redirected back to " \
                                "'/server_side_log_throw_raise_invoker'. See server logs for output.")
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

describe "Manual Rendering", :js do
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
    within("#HelloWorldRehydratable-react-component-1") do
      find("input").set "Should update"
      within("h3") do
        expect(page).to have_content "Should update"
      end
    end
  end
end

describe "returns hash if hash_result == true even with prerendering error", :js do
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
      expected_text = 'Props: {"apiRequestResponse":{"count":0,"country":[],"name":"ReactOnRails"},' \
                      '"helloWorldData":{"name":"Mr. Server Side Rendering"}}'
      expect(page).to have_text expected_text
      expect(page).to have_css "title", text: /\ACustom page title\z/, visible: :hidden
      expect(page.html).to include("[SERVER] RENDERED ReactHelmetApp to dom node with id")
      expect(page.html).not_to include("not defined for server rendering")
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

describe "setTimeout", :rack_test do
  subject { page }

  before { visit "/server_render_with_timeout" }

  it "sets the variable correctly" do
    expect(page).to have_text "this value is set by setTimeout during SSR"
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

describe "loadable components", :js do
  before { visit "loadable/A" }

  it "displays the proper text" do
    expect(page).to have_text "This is Page A."
    expect(page.html).to include("[SERVER] RENDERED Loadable")
  end
end

shared_examples "React Component Shared Store" do |url|
  subject { page }

  before { visit url }

  context url do
    it "Type in one component changes the other component" do
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
