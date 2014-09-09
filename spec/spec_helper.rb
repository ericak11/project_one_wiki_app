ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'capybara/rspec'
require 'rack_session_access'
require './app'
require 'pry'

Capybara.app = App

RSpec.configure do |config|
  config.include Capybara::DSL
end

binding.pry

App.configure do |app|
  app.use RackSessionAccess::Middleware
end
