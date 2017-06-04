# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe PagesController, type: :controller do
  describe "GET #index" do
    it "renders the :index template" do
      get :index
      expect(response).to render_template :index
    end
  end
end
