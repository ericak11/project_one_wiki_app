require 'sinatra/base'
require 'redis'
require 'json'
require 'uri'
require 'httparty'
require 'redcarpet'

class App < Sinatra::Base

  ########################
  # Configuration
  ########################

  configure do
    enable :logging
    enable :method_override
    enable :sessions
    REDIS_URL = ENV["REDISTOGO_URL"]
    uri = URI.parse(ENV["REDISTOGO_URL"])
    $redis = Redis.new({:host => uri.host,
                        :port => uri.port,
                        :password => uri.password})
    set :session_secret, 'super secret'
  end

  before do
    logger.info "Request Headers: #{headers}"
    logger.warn "Params: #{params}"
  end

  after do
    logger.info "Response Headers: #{response.headers}"
  end

  ########################
  # API KEYS
  ########################
  CLIENT_ID     = ""
  CLIENT_SECRET = ""
  CALLBACK_URL  = "http://??????/oauth_callback"

  ########################
  # Routes
  ########################

  get('/') do
    base_url = "https://accounts.google.com/o/oauth2/auth"
    state = SecureRandom.urlsafe_base64
    # storing state in session because we need to compare it in a later request
    session[:state] = state
    @url = "#{base_url}?client_id=#{CLIENT_ID}&response_type=code&redirect_uri=#{CALLBACK_URL}&state=#{state}"
    render(:erb, :index)
  end

  get('/logout') do
    session[:access_token] = nil
    redirect to ('/')
  end
  # See a specific document - finds it by name
  get('/documents/:id_name') do
    render(:erb, :document)
  end

  # See a specific document - and make changes
  get('/documents/:id_name/edit') do
    render(:erb, :document)
  end

  # Create a new document - refers to document class
  get('/documents/new') do
    render(:erb, :create_doc)
  end

  # User page wher user can see all their documents
  get('/users/:user_id') do
    render(:erb, :user_page)
  end

  # Creates a new document on redis?
  post('/documents') do

    redirect to ()
  end

  # Remove a document that you created
  delete('/documents/:id_name') do

    redirect to ()
  end

  # Edit a ocument
  put('/documents/:id_name') do

    redirect to ()
  end

  get('/oauth_callback') do
    code = params[:code]
    # compare the states to ensure the information is from who we think it is
    if session[:state] == params[:state]
      # send a POST
      response = HTTParty.post(
        "https://api.dropbox.com/1/oauth2/token",
        :body => {
          code: code,
          grant_type: "authorization_code",
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          redirect_uri: CALLBACK_URL,
          },
        :headers => {
          "Accept" => "application/json"
        },)
      session[:access_token] = response["access_token"]
      ## gets user info
      get_stuff = HTTParty.post(
          "https://api.dropbox.com/1/account/info",
          :headers => {
            "Authorization" => "Bearer #{session[:access_token]}",
            "Accept" => "application/json",
          },)
    end
    redirect to("/")
  end

end
