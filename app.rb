require 'sinatra'
require 'sass'
require 'coffee-script'

configure :development do
  require 'rack/reloader'
  Sinatra::Application.reset!
  use Rack::Reloader

  require 'better_errors'
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path("..", __FILE__)
end


get '/screen.css' do
  scss :"stylesheets/screen"
end

get '/:name.js' do
  coffee :"#{params[:name]}"
end

get '/' do
  erb :index, :layout => :layout
end

get '/:name' do
  erb :"/#{params[:name].to_sym}"
end