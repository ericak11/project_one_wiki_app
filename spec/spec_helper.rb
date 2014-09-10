ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'capybara/rspec'
require 'rack_session_access'
require './app'
require 'pry'

App.configure do |app|
  app.use RackSessionAccess::Middleware
end

Capybara.app = App

RSpec.configure do |config|
  config.include Capybara::DSL
end


