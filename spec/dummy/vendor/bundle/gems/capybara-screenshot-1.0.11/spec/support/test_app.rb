require 'sinatra/base'

Sinatra::Application.root = '.'

class TestApp < Sinatra::Base
  get '/' do
    'This is the root page'
  end

  get '/different_page' do
    'This is a different page'
  end
end
