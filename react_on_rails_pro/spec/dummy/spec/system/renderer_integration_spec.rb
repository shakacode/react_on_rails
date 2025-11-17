# frozen_string_literal: true

require "rails_helper"

describe "Shared Redux store example", :server_rendering do
  subject { page }

  before { visit server_side_hello_world_shared_store_path }

  context "with enabled JS", :js do
    it "Has correct heading and text inside the text input" do
      expect(page).to have_css("h3", text: /\ARedux Hello, Mr. Server Side Rendering!\z/)
      expect(page).to have_css("input[type='text'][value='Mr. Server Side Rendering']")
    end

    it "updates header in reaction to text input changes" do
      new_value = "new value"
      all("input[type='text']")[0].set(new_value)
      expect(page).to have_css("h3", text: /\ARedux Hello, #{new_value}!\z/)
    end
  end
end
