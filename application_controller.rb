require './helpers/app_helper'
require_relative './new_user'
require_relative './new_document'
class ApplicationController < Sinatra::Base
  configure do
    enable :logging
    enable :method_override
    enable :sessions
    use RackSessionAccess if environment == :test
    REDIS_URL = ENV['REDISTOGO_URL']
    uri = URI.parse(ENV['REDISTOGO_URL'])
    $redis = Redis.new(host: uri.host,
                       port: uri.port,
                       password: uri.password)
    set :session_secret, 'super secret'
    $redis.setnx('doc_counter', 0)
    $redis.setnx('article_tags', %w(Ruby Sinatra GitHub JSON HTTParty HTML CSS API bash class module hash array Git))
  end

  before do
    logger.info "Request Headers: #{headers}"
    logger.warn "Params: #{params}"
  end

  after do
    logger.info "Response Headers: #{response.headers}"
  end

  helpers AppHelper
  helpers DocHelper
  helpers UserHelper
end
