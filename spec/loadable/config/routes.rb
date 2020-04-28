# frozen_string_literal: true

Rails.application.routes.draw do
  root "pages#index"
  get "*path", to: "pages#index"
end
