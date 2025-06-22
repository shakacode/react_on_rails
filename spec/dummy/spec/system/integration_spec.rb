# frozen_string_literal: true

require "rails_helper"

RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = nil

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

# Basic ReactOnRails specs
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

# ReactOnRails Pro specific specs (Streaming and RSC related)
shared_examples "streamed component tests" do |path, selector|
  subject { page }

  it "renders the component" do
    visit path
    expect(page).to have_text "Header for AsyncComponentsTreeForTesting"
    expect(page).to have_text "Footer for AsyncComponentsTreeForTesting"
  end

  it "hydrates the component" do
    visit path
    expect(page.html).to include("client-bundle.js")
    change_text_expect_dom_selector(selector)
  end

  it "renders the page completely on server and displays content on client even without JavaScript" do
    # Don't add client-bundle.js to the page to ensure that the app is not hydrated
    visit "#{path}?skip_js_packs=true"
    expect(page.html).not_to include("client-bundle.js")
    # Ensure that the component state is not updated
    change_text_expect_dom_selector(selector, expect_no_change: true)

    expect(page).not_to have_text "Loading branch1"
    expect(page).not_to have_text "Loading branch2"
    expect(page).not_to have_text(/Loading branch1 at level \d+/)
    expect(page).to have_text(/branch1 \(level \d+\)/, count: 5)
  end

  shared_examples "shows loading fallback while rendering async components" do |skip_js_packs|
    it "shows the loading fallback while rendering async components" \
       "#{skip_js_packs ? ' when the page is not hydrated' : ''}" do
      path = "#{path}#{skip_js_packs ? '?skip_js_packs=true' : ''}"
      chunks_count = 0
      chunks_count_having_branch1_loading_fallback = 0
      chunks_count_having_branch2_loading_fallback = 0
      navigate_with_streaming(path) do |_content|
        chunks_count += 1
        chunks_count_having_branch1_loading_fallback += 1 if page.has_text?(/Loading branch1 at level \d+/)
        chunks_count_having_branch2_loading_fallback += 1 if page.has_text?(/Loading branch2 at level \d+/)
      end

      expect(chunks_count_having_branch1_loading_fallback).to be_between(3, 6)
      expect(chunks_count_having_branch2_loading_fallback).to be_between(1, 3)
      expect(page).not_to have_text(/Loading branch1 at level \d+/)
      expect(page).not_to have_text(/Loading branch2 at level \d+/)
      expect(chunks_count).to be_between(5, 7)

      # Check if the page is hydrated or not
      change_text_expect_dom_selector(selector, expect_no_change: skip_js_packs)
    end
  end

  it_behaves_like "shows loading fallback while rendering async components", false
  it_behaves_like "shows loading fallback while rendering async components", true

  it "replays console logs" do
    visit path
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
    chunks_count_containing_server_logs = 0
    navigate_with_streaming(path) do |content|
      chunks_count += 1
      logs = page.driver.browser.logs.get(:browser)
      info = logs.select { |log| log.level == "INFO" }
      info_messages = info.map(&:message)
      errors = logs.select { |log| log.level == "SEVERE" }
      errors_messages = errors.map(&:message)

      next if content.empty? || chunks_count == 1

      if info_messages.any?(/\[SERVER\] branch1 \(level \d+\)/) && errors_messages.any?(
        /"\[SERVER\] Error message" "{\\"branchName\\":\\"branch1\\",\\"level\\":\d+}/
      )
        chunks_count_containing_server_logs += 1
      end
    end
    expect(chunks_count).to be >= 5
    expect(chunks_count_containing_server_logs).to be > 2
  end

  it "doesn't hydrate status component if packs are not loaded" do
    # visit waits for the page to load, so we ensure that the page is loaded before checking the hydration status
    visit "#{path}?skip_js_packs=true"
    expect(page).to have_text "HydrationStatus: Streaming server render"
    expect(page).not_to have_text "HydrationStatus: Hydrated"
    expect(page).not_to have_text "HydrationStatus: Page loaded"
  end

  it "hydrates loaded components early before the full page is loaded" do
    chunks_count = 0
    status_component_hydrated_on_chunk = nil
    input_component_hydrated_on_chunk = nil
    navigate_with_streaming(path) do |_content|
      chunks_count += 1

      # The code that updates the states to Hydrated is executed on `useEffect` which is called only on hydration
      if status_component_hydrated_on_chunk.nil? && page.has_text?("HydrationStatus: Hydrated")
        status_component_hydrated_on_chunk = chunks_count
      end

      if input_component_hydrated_on_chunk.nil?
        begin
          # Checks that the input field is hydrated
          change_text_expect_dom_selector(selector)
          input_component_hydrated_on_chunk = chunks_count
        rescue RSpec::Expectations::ExpectationNotMetError, Capybara::ElementNotFound
          # Do nothing if the test fails - component not yet hydrated
        end
      end
    end

    # The component should be hydrated before the full page is loaded
    expect(status_component_hydrated_on_chunk).to be < chunks_count
    expect(input_component_hydrated_on_chunk).to be < chunks_count
    expect(page).to have_text "HydrationStatus: Page loaded"
  end
end

describe "Pages/stream_async_components_for_testing", :js do
  it_behaves_like "streamed component tests", "/stream_async_components_for_testing",
                  "#AsyncComponentsTreeForTesting-react-component-0"
end

describe "React Router Sixth Page", :js do
  it_behaves_like "streamed component tests", "/server_router/streaming-server-component",
                  "#ServerComponentRouter-react-component-0"
end

def rsc_payload_fetch_requests
  fetch_requests_while_streaming.select { |request| request[:url].include?("/rsc_payload/") }
end

shared_examples "RSC payload only fetched if component is not server-side rendered" do |server_rendered_path,
                                                                                        client_rendered_path|
  before do
    # Clear the browser logs. so any test reading the logs will only read the logs from the current page navigation
    page.driver.browser.logs.get(:browser)
  end

  it "doesn't fetch RSC payload if component is server-side rendered" do
    navigate_with_streaming server_rendered_path

    expect(rsc_payload_fetch_requests).to eq([])
  end

  it "fetches RSC payload if component is client-side rendered" do
    navigate_with_streaming client_rendered_path

    expect(rsc_payload_fetch_requests.size).to be > 0
  end
end

describe "Pages/server_router/streaming-server-component rsc payload fetching", :js do
  it_behaves_like "RSC payload only fetched if component is not server-side rendered", "/server_router/sixth",
                  "/server_router_client_render/streaming-server-component"
end

describe "Pages/stream_async_components_for_testing rsc payload fetching", :js do
  it_behaves_like "RSC payload only fetched if component is not server-side rendered",
                  "/stream_async_components_for_testing", "/stream_async_components_for_testing_client_render"
end

describe "Pages/server_router", :js do
  subject { page }

  it "navigates between pages" do
    navigate_with_streaming("/server_router/simple-server-component")
    expect_client_component_inside_server_component_hydrated(page)
    expect(page).not_to have_text("Server Component Title")
    expect(page).not_to have_text("Server Component Description")
    expect(rsc_payload_fetch_requests).to eq([])

    click_link "Another Simple Server Component"
    expect(rsc_payload_fetch_requests).to eq([
                                               { url: "/rsc_payload/MyServerComponent?props=%7B%7D" }
                                             ])

    expect(page).to have_text("Server Component Title")
    expect(page).to have_text("Server Component Description")
    expect(page).not_to have_text("Post 1")
    expect(page).not_to have_text("Content 1")
  end

  it "streams the navigation between pages" do
    navigate_with_streaming("/server_router/simple-server-component")

    click_link "Server Component with visible streaming behavior"
    expect(rsc_payload_fetch_requests.first[:url]).to include("/rsc_payload/AsyncComponentsTreeForTesting")

    expect(page).not_to have_text("Post 1")
    expect(page).not_to have_text("Content 1")
    expect(page).to have_text("Loading branch1 at level 3...", wait: 5)

    # Client component is hydrated before the full page is loaded
    expect(page).to have_text("HydrationStatus: Hydrated")
    change_text_expect_dom_selector("#ServerComponentRouter-react-component-0")

    expect(page).to have_text("Loading branch1 at level 1...", wait: 5)
    expect(page).to have_text("branch1 (level 1)")
    expect(page).not_to have_text("Loading branch1 at level 1...")
    expect(page).not_to have_text("Loading branch1 at level 3...")
  end
end

def async_on_server_sync_on_client_client_render_logs
  logs = page.driver.browser.logs.get(:browser)
  component_logs = logs.select { |log| log.message.include?(component_logs_tag) }
  client_component_logs = component_logs.reject { |log| log.message.include?("[SERVER]") }
  client_component_logs.map do |log|
    # Extract string between double quotes that contains component_logs_tag
    # The string can contain escaped double quotes (\").
    message = log.message.match(/"([^"]*(?:\\"[^"]*)*#{component_logs_tag}[^"]*(?:\\"[^"]*)*)"/)[1]
    JSON.parse("\"#{message}\"").gsub(component_logs_tag, "").strip
  end
end

def expect_client_component_inside_server_component_hydrated(page)
  expect(page).to have_text("Post 1")
  expect(page).to have_text("Content 1")
  expect(page).to have_button("Toggle")

  # Check that the client component is hydrated
  click_button "Toggle"
  expect(page).not_to have_text("Content 1")
end

# The following two tests ensure that server components can be rendered inside client components
# and ensure that no race condition happens that make client side refetch the RSC payload
# that is already embedded in the HTML
# By ensuring that the client component is only hydrated after the server component is
# rendered and its HTML is embedded in the page
describe "Pages/async_on_server_sync_on_client_client_render", :js do
  subject(:async_component) { find_by_id("AsyncOnServerSyncOnClient-react-component-0") }

  let(:component_logs_tag) { "[AsyncOnServerSyncOnClient]" }

  before do
    # Clear the browser logs. so any test reading the logs will only read the logs from the current page navigation
    page.driver.browser.logs.get(:browser)
  end

  it "all components are rendered on client" do
    chunks_count = 0
    # Nothing is rendered on the server
    navigate_with_streaming("/async_on_server_sync_on_client_client_render") do |content|
      next unless content.include?("Understanding Server/Client Component Hydration Patterns")

      chunks_count += 1
      # This part is rendered from the rails view
      expect(content).to include("Understanding Server/Client Component Hydration Patterns")
      # remove the rails view content
      rails_view_index = content.index("Understanding Server/Client Component Hydration Patterns")
      content = content[0...rails_view_index]

      # This part is rendered from the server component on client
      expect(content).not_to include("Async Component 1 from Suspense Boundary1")
      expect(content).not_to include("Async Component 1 from Suspense Boundary2")
      expect(content).not_to include("Async Component 1 from Suspense Boundary3")
    end
    expect(chunks_count).to be <= 1

    # After client side rendering, the component should exist in the DOM
    expect(async_component).to have_text("Async Component 1 from Suspense Boundary1")
    expect(async_component).to have_text("Async Component 1 from Suspense Boundary2")
    expect(async_component).to have_text("Async Component 1 from Suspense Boundary3")

    # Should render "Simple Component" server component
    expect(async_component).to have_text("Post 1")
    expect(async_component).to have_button("Toggle")
  end

  it "fetches RSC payload of the Simple Component to render it on client" do
    fetch_requests_while_streaming

    navigate_with_streaming "/async_on_server_sync_on_client_client_render"
    expect(async_component).to have_text("Post 1")
    expect(async_component).to have_button("Toggle")
    fetch_requests = fetch_requests_while_streaming
    expect(fetch_requests).to eq([
                                   { url: "/rsc_payload/SimpleComponent?props=%7B%7D" }
                                 ])
  end

  it "renders the client components on the client side in a sync manner" do
    navigate_with_streaming "/async_on_server_sync_on_client_client_render"

    component_logs = async_on_server_sync_on_client_client_render_logs
    # The last log happen if the test catched the re-render of the suspensed component on the client
    expect(component_logs.size).to be_between(13, 15)

    # To understand how these logs show that components are rendered in a sync manner,
    # check the component page in the dummy app `/async_on_server_sync_on_client_client_render`
    expect(component_logs[0...13]).to eq([
                                           "AsyncContent rendered",
                                           async_component_rendered_message(0, 0),
                                           async_component_rendered_message(0, 1),
                                           async_component_rendered_message(1, 0),
                                           async_component_rendered_message(2, 0),
                                           async_component_rendered_message(3, 0),
                                           async_loading_component_message(3),
                                           async_component_hydrated_message(0, 0),
                                           async_component_hydrated_message(0, 1),
                                           async_component_hydrated_message(1, 0),
                                           async_component_hydrated_message(2, 0),
                                           "AsyncContent has been mounted",
                                           async_component_rendered_message(3, 0)
                                         ])
  end

  it "hydrates the client component inside server component" do # rubocop:disable RSpec/NoExpectationExample
    navigate_with_streaming "/async_on_server_sync_on_client_client_render"
    expect_client_component_inside_server_component_hydrated(async_component)
  end
end

describe "Pages/async_on_server_sync_on_client", :js do
  subject(:async_component) { find_by_id("AsyncOnServerSyncOnClient-react-component-0") }

  let(:component_logs_tag) { "[AsyncOnServerSyncOnClient]" }

  before do
    # Clear the browser logs. so any test reading the logs will only read the logs from the current page navigation
    page.driver.browser.logs.get(:browser)
  end

  it "all components are rendered on server" do
    received_server_html = ""
    navigate_with_streaming("/async_on_server_sync_on_client") do |content|
      received_server_html += content
    end
    expect(received_server_html).to include("Async Component 1 from Suspense Boundary1")
    expect(received_server_html).to include("Async Component 1 from Suspense Boundary2")
    expect(received_server_html).to include("Async Component 1 from Suspense Boundary3")
    expect(received_server_html).to include("Post 1")
    expect(received_server_html).to include("Content 1")
    expect(received_server_html).to include("Toggle")
    expect(received_server_html).to include(
      "Understanding Server/Client Component Hydration Patterns"
    )
  end

  it "doesn't fetch the RSC payload of the server component in the page" do
    navigate_with_streaming "/async_on_server_sync_on_client"
    expect(fetch_requests_while_streaming).to eq([])
  end

  it "hydrates the client component inside server component" do # rubocop:disable RSpec/NoExpectationExample
    navigate_with_streaming "/async_on_server_sync_on_client"
    expect_client_component_inside_server_component_hydrated(page)
  end

  it "progressively renders the page content" do
    rendering_stages_count = 0
    navigate_with_streaming "/async_on_server_sync_on_client" do |content|
      # The first stage when all components are still being rendered on the server
      if content.include?("Loading Suspense Boundary3")
        rendering_stages_count += 1
        expect(async_component).to have_text("Loading Suspense Boundary3")
        expect(async_component).to have_text("Loading Suspense Boundary2")
        expect(async_component).to have_text("Loading Suspense Boundary1")

        expect(async_component).not_to have_text("Post 1")
        expect(async_component).not_to have_text("Async Component 1 from Suspense Boundary1")
        expect(async_component).not_to have_text("Async Component 1 from Suspense Boundary2")
        expect(async_component).not_to have_text("Async Component 1 from Suspense Boundary3")
      # The second stage when the Suspense Boundary3 (with 1000ms delay) is rendered on the server
      elsif content.include?("Async Component 1 from Suspense Boundary3")
        rendering_stages_count += 1
        expect(async_component).to have_text("Async Component 1 from Suspense Boundary3")
        expect(async_component).not_to have_text("Post 1")
        expect(async_component).not_to have_text("Async Component 1 from Suspense Boundary1")
        expect(async_component).not_to have_text("Async Component 1 from Suspense Boundary2")
        expect(async_component).not_to have_text("Loading Suspense Boundary3")
      # The third stage when the Suspense Boundary2 (with 3000ms delay) is rendered on the server
      elsif content.include?("Async Component 1 from Suspense Boundary2")
        rendering_stages_count += 1
        expect(async_component).to have_text("Async Component 1 from Suspense Boundary3")
        expect(async_component).to have_text("Post 1")
        expect(async_component).to have_text("Async Component 1 from Suspense Boundary1")
        expect(async_component).to have_text("Async Component 1 from Suspense Boundary2")
        expect(async_component).not_to have_text("Loading Suspense Boundary2")

        # Expect that client component is hydrated
        expect(async_component).to have_text("Content 1")
        expect(async_component).to have_button("Toggle")

        # Expect that the client component is hydrated
        click_button "Toggle"
        expect(page).not_to have_text("Content 1")
      end
    end
    expect(rendering_stages_count).to be 3
  end

  it "doesn't hydrate client components until they are rendered on the server" do
    rendering_stages_count = 0
    component_logs = []

    navigate_with_streaming "/async_on_server_sync_on_client" do |content|
      component_logs += async_on_server_sync_on_client_client_render_logs

      # The first stage when all components are still being rendered on the server
      if content.include?("<div>Loading Suspense Boundary3</div>")
        rendering_stages_count += 1
        expect(component_logs).not_to include(async_component_rendered_message(0, 0))
        expect(component_logs).not_to include(async_component_rendered_message(1, 0))
        expect(component_logs).not_to include(async_component_rendered_message(2, 0))
      # The second stage when the Suspense Boundary3 (with 1000ms delay) is rendered on the server
      elsif content.include?("<div>Async Component 1 from Suspense Boundary3 (1000ms server side delay)</div>")
        rendering_stages_count += 1
        expect(component_logs).to include("AsyncContent rendered")
        expect(component_logs).to include("AsyncContent has been mounted")
        expect(component_logs).not_to include(async_component_rendered_message(1, 0))
      # The third stage when the Suspense Boundary2 (with 3000ms delay) is rendered on the server
      elsif content.include?("<div>Async Component 1 from Suspense Boundary2 (3000ms server side delay)</div>")
        rendering_stages_count += 1
        expect(component_logs).to include(async_component_rendered_message(1, 0))
        expect(component_logs).to include(async_component_rendered_message(2, 0))
      end
    end

    expect(rendering_stages_count).to be 3
  end

  it "hydrates the client component inside server component before the full page is loaded" do
    chunks_count = 0
    client_component_hydrated_on_chunk = nil
    component_logs = []
    navigate_with_streaming "/async_on_server_sync_on_client" do |_content|
      chunks_count += 1
      component_logs += async_on_server_sync_on_client_client_render_logs

      if client_component_hydrated_on_chunk.nil? && component_logs.include?(async_component_hydrated_message(3, 0))
        client_component_hydrated_on_chunk = chunks_count
        expect_client_component_inside_server_component_hydrated(async_component)
      end
    end
    expect(client_component_hydrated_on_chunk).to be < chunks_count
  end

  it "Server component is pre-rendered on the server and not showing loading component on the client" do
    navigate_with_streaming "/async_on_server_sync_on_client"
    component_logs = async_on_server_sync_on_client_client_render_logs
    expect(component_logs).not_to include(async_loading_component_message(3))
  end
end
