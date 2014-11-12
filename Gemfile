source 'https://rubygems.org'

ruby '2.1.2'

gem 'sinatra', '1.4.5'
gem 'redis',  '3.1.0'
gem 'redcarpet', '3.1.2'
gem 'httparty', '0.13.1'
gem 'reverse_markdown', '0.5.1'
gem 'diffy', '3.0.6'
gem 'sequel'
gem 'pg'


# only used in development locally
group :development do
  gem 'pry'
  gem 'shotgun'
end

group :production do
  # gems specific just in the production environment
end

group :test do
  gem 'rspec'
  gem 'capybara'
  gem 'rack_session_access'
end
