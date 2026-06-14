# frozen_string_literal: true

require "rails_helper"

# Integration coverage for React 19.2 <Activity> with react_component
# (issue #3883, Phase 1). The ActivityTabSwitcher component mounts both tabs,
# wrapping the inactive one in <Activity mode="hidden">.
#
# Verified React 19.2 SSR behavior (react-dom renderToString): visible Activity
# content is prerendered (delimited by <!--&--> / <!--/&--> markers); hidden
# Activity subtrees are OMITTED from the server HTML and render client-side
# after hydration. The :js system spec (spec/system/activity_spec.rb) covers
# hydration and state preservation; this spec pins the server-rendered HTML.
describe "React 19.2 Activity component", :server_rendering do
  it "server-renders only the visible Activity tab when prerender: true" do
    get server_side_activity_path
    expect(response).to have_http_status(:ok)

    html_nodes = Nokogiri::HTML(response.body)
    component = html_nodes.at_css("div#ActivityTabSwitcher-react-component-0")

    # Visible tab (initialTab: "profile") is prerendered.
    profile_panel = component.at_css('[data-tab-panel="profile"]')
    expect(profile_panel).not_to be_nil
    expect(component.at_css('input[data-draft-input="profile"]')).not_to be_nil
    expect(profile_panel.at_css('[data-effect-status="profile"]')&.text).to eq("effects never mounted")

    # Hidden Activity subtree is omitted from server HTML (renders on client).
    expect(component.at_css('[data-tab-panel="drafts"]')).to be_nil

    # Both tab buttons render (they are outside the Activity boundaries).
    expect(component.css("button[data-tab-button]").map { |btn| btn["data-tab-button"] })
      .to contain_exactly("profile", "drafts")
  end

  it "renders an empty mount node when prerender: false" do
    get client_side_activity_path
    expect(response).to have_http_status(:ok)

    html_nodes = Nokogiri::HTML(response.body)
    expect(html_nodes.css("div#ActivityTabSwitcher-react-component-0").children.size).to eq(0)
  end
end
