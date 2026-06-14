# frozen_string_literal: true

require "rails_helper"

# Browser coverage for React 19.2 <Activity> with react_component
# (issue #3883, Phase 1).
#
# Hidden tabs stay mounted inside <Activity mode="hidden">, so their input
# state must survive tab switches in both CSR (prerender: false) and
# SSR-hydrate (prerender: true) modes.
#
# Hydration-mismatch detection: spec/support/selenium_logger.rb raises on any
# SEVERE browser console message after each :js example. React logs hydration
# mismatches as console errors, so these examples fail if hydration mismatches.
shared_examples "Activity tab switcher" do
  let(:component_selector) { "div#ActivityTabSwitcher-react-component-0" }

  it "preserves hidden tab input state across tab switches" do
    within(component_selector) do
      # Initially the profile tab is visible and the drafts tab is hidden
      # (mounted but display: none under <Activity mode="hidden">).
      expect(page).to have_css('[data-tab-panel="profile"]', visible: :visible)

      find('input[data-draft-input="profile"]').set("draft typed on profile tab")

      # Switch to the drafts tab; the profile panel hides but stays in the DOM.
      find('button[data-tab-button="drafts"]').click
      expect(page).to have_css('[data-tab-panel="drafts"]', visible: :visible)
      expect(page).to have_css('[data-tab-panel="profile"]', visible: :hidden)

      find('input[data-draft-input="drafts"]').set("draft typed on drafts tab")

      # Switch back: profile draft preserved, effects re-mounted.
      find('button[data-tab-button="profile"]').click
      expect(page).to have_css('[data-tab-panel="profile"]', visible: :visible)
      expect(find('input[data-draft-input="profile"]').value).to eq("draft typed on profile tab")
      expect(find('[data-effect-status="profile"]')).to have_text("effects mounted")

      # And the drafts draft survives being hidden again.
      find('button[data-tab-button="drafts"]').click
      expect(find('input[data-draft-input="drafts"]').value).to eq("draft typed on drafts tab")
    end
  end
end

describe "React 19.2 Activity", :js do
  context "with CSR (prerender: false)" do
    before { visit client_side_activity_path }

    include_examples "Activity tab switcher"
  end

  context "with SSR-hydrate (prerender: true)" do
    before { visit server_side_activity_path }

    it "hydrates the server-rendered visible tab and client-renders the hidden tab" do
      within("div#ActivityTabSwitcher-react-component-0") do
        # Server HTML contains only the visible tab; after hydration React
        # renders the hidden Activity subtree on the client (display: none).
        expect(page).to have_css('[data-tab-panel="profile"]', visible: :visible)
        expect(page).to have_css('[data-tab-panel="drafts"]', visible: :hidden)
      end
    end

    include_examples "Activity tab switcher"
  end
end
