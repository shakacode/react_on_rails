class CssController < ApplicationController
  def test
    file = params[:file] + '.css'
    render text: Rails.application.assets[file]
  end
end
