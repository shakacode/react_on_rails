require "rails_helper"

def change_text_expect_dom_selector(dom_selector)
  new_text = "John Doe"

  within(dom_selector) do
    find("input").set new_text
    within("h3") do
      is_expected.to have_content new_text
    end
  end
end

shared_examples "React Component" do |dom_selector|
  scenario { is_expected.to have_css dom_selector }

  scenario "changes name in message according to input" do
    change_text_expect_dom_selector(dom_selector)
  end
end

feature "Pages/Index", :js do
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
      include_examples "React Component", "div#HelloWorld-react-component-5"
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

feature "Turbolinks across pages", :js do
  subject { page }

  scenario "changes name in message according to input" do
    visit "/client_side_hello_world"
    change_text_expect_dom_selector("#HelloWorld-react-component-0")
    click_link "Hello World Component Server Rendered, with extra options"
    change_text_expect_dom_selector("#my-hello-world-id")
  end
end

feature "Pages/client_side_log_throw", :js do
  subject { page }
  background { visit "/client_side_log_throw" }

  scenario "client side logging and error handling", driver: js_errors_driver do
    is_expected.to have_text "This example demonstrates client side logging and error handling."
  end
end

feature "Pages/Pure Component", :js do
  subject { page }
  background { visit "/pure_component" }

  scenario { is_expected.to have_text "This is a Pure Component!" }
end

feature "Pages/server_side_log_throw", :js do
  subject { page }
  background { visit "/server_side_log_throw" }

  scenario "page has server side throw messages", driver: js_errors_driver do
    expect(subject).to have_text "This example demonstrates server side logging and error handling."
    expect(subject).to have_text "Exception in rendering!\n\nMessage: throw in HelloWorldContainer"
  end
end

feature "Pages/server_side_log_throw_raise" do
  subject { page }
  background { visit "/server_side_log_throw_raise" }

  scenario "redirects to /client_side_hello_world and flashes an error" do
    expect(current_path).to eq("/client_side_hello_world")
    flash_message = page.find(:css, ".flash").text
    expect(flash_message).to eq("Error prerendering in react_on_rails. See server logs.")
  end
end

feature "Pages/index after using browser's back button", :js do
  subject { page }
  background do
    visit root_path
    visit "/client_side_hello_world"
    go_back
  end

  include_examples "React Component", "div#ReduxApp-react-component-0"
end

feature "React Router", js: true, driver: js_errors_driver do
  subject { page }
  background do
    visit "/"
    click_link "React Router"
  end
  context "/react_router" do
    it { is_expected.to have_text("Woohoo, we can use react-router here!") }
    scenario "clicking links correctly renders other pages" do
      click_link "Router First Page"
      expect(current_path).to eq("/react_router/first_page")
      first_page_header_text = page.find(:css, "h2").text
      expect(first_page_header_text).to eq("React Router First Page")

      click_link "Router Second Page"
      expect(current_path).to eq("/react_router/second_page")
      second_page_header_text = page.find(:css, "h2").text
      expect(second_page_header_text).to eq("React Router Second Page")
    end
  end
end

feature "Manual Rendering", :js do
  subject { page }
  background { visit "/client_side_manual_render" }
  scenario "renderer function is called successfully" do
    header_text = page.find(:css, "h1").text
    expect(header_text).to eq("Manual Render Example")
    expect(subject).to have_text "If you can see this, you can register renderer functions."
  end
end

feature "Code Splitting", :js do
  subject { page }
  background { visit "/deferred_render_with_server_rendering" }
  scenario "clicking on async route causes async component to be fetched" do
    header_text = page.find(:css, "h1").text

    expect(header_text).to eq("Deferred Rendering")
    expect(subject).to_not have_text "Noice!"

    click_link "Test Async Route"
    expect(current_path).to eq("/deferred_render_with_server_rendering/async_page")
    expect(subject).to have_text "Noice!"
  end
end

feature "Code Splitting w/ Server Rendering", :js do
  subject { page }
  background { visit "/deferred_render_with_server_rendering/async_page" }
  scenario "loading an asyncronous route should not cause a client/server checksum mismatch" do
    root = page.find(:xpath, "//div[@data-reactroot]")
    expect(root["data-react-checksum"].present?).to be(true)
  end
end

feature "renderedHtml from generator function", :js do
  subject { page }
  background { visit "/rendered_html" }
  scenario "renderedHtml should not have any errors" do
    expect(subject).to have_text 'Props: {"hello":"world"}'
    expect(subject.html).to include("[SERVER] RENDERED RenderedHtml to dom node with id")
  end
end

feature "generator function returns renderedHtml as an object with additional HTML markups" do
  shared_examples "renderedHtmls should not have any errors and set correct page title" do
    subject { page }
    background { visit react_helmet_path }
    scenario "renderedHtmls should not have any errors" do
      expect(subject).to have_text 'Props: {"hello":"world"}'
      expect(subject).to have_css "title", text: /\ACustom page title\z/, visible: false
      expect(subject.html).to include("[SERVER] RENDERED ReactHelmetApp to dom node with id")
    end
  end

  describe "with disabled JS" do
    include_examples "renderedHtmls should not have any errors and set correct page title"
  end

  describe "with enabled JS", :js do
    include_examples "renderedHtmls should not have any errors and set correct page title"
  end
end

feature "display images", :js do
  subject { page }
  background { visit "/image_example" }
  scenario "image_example should not have any errors" do
    expect(subject).to have_text "Here is a label with a background-image from the CSS modules imported"
    expect(subject.html).to include("[SERVER] RENDERED ImageExample to dom node with id")
  end
end

shared_examples "React Component Shared Store" do |url|
  subject { page }
  background { visit url }
  context url do
    scenario "Type in one component changes the other component" do
      expect(current_path).to eq(url)
      new_text = "John Doe"
      new_text2 = "Jane Smith"
      within("#ReduxSharedStoreApp-react-component-0") do
        find("input").set new_text
        within("h3") do
          is_expected.to have_content new_text
        end
      end
      within("#ReduxSharedStoreApp-react-component-1") do
        within("h3") do
          is_expected.to have_content new_text
        end
        find("input").set new_text2
      end
      within("#ReduxSharedStoreApp-react-component-0") do
        within("h3") do
          is_expected.to have_content new_text2
        end
      end
    end
  end
end

feature "2 react components, 1 store, client only", :js do
  include_examples "React Component Shared Store", "/client_side_hello_world_shared_store"
end

feature "2 react components, 1 store, server side", :js do
  include_examples "React Component Shared Store", "/server_side_hello_world_shared_store"
end

feature "2 react components, 1 store, client only, controller setup", :js do
  include_examples "React Component Shared Store", "/client_side_hello_world_shared_store_controller"
end

feature "2 react components, 1 store, server side, controller setup", :js do
  include_examples "React Component Shared Store", "/server_side_hello_world_shared_store_controller"
end

feature "2 react components, 1 store, client only, defer", :js do
  include_examples "React Component Shared Store", "/client_side_hello_world_shared_store_defer"
end

feature "2 react components, 1 store, server side, defer", :js do
  include_examples "React Component Shared Store", "/server_side_hello_world_shared_store_defer"
end
