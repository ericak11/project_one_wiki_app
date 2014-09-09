ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'capybara/rspec'
require 'rack_session_access/capybara'
require './app'

Capybara.app = App

RSpec.configure do |config|
  config.include Capybara::DSL
end

App.configure do |app|
  app.use RackSessionAccess::Middleware
end
