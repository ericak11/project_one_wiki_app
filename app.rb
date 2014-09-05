require 'sinatra/base'
require 'redis'
require 'json'
require 'uri'
require 'httparty'
require 'redcarpet'
# require 'pry'
require_relative './new_user'

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
  CLIENT_ID     = "435810356359-lv1hhiqgrn7ccpu1hs6cl0jenuetdore.apps.googleusercontent.com"
  CLIENT_SECRET = "KeWjgff5KkMh4oORP0x-gsdZ"
  CALLBACK_URL  = "http://127.0.0.1:3000/oauth2callback"

  # HEROKU
  # CLIENT_ID     = "435810356359-a7hc6g5ih01shh5bo6cj5k2fuqrhsuts.apps.googleusercontent.com"
  # CLIENT_SECRET = "6LNtL3QfRb7Jar8JujC70TMU"
  # CALLBACK_URL  = "http://ancient-inlet-1734.herokuapp.com:3000/oauth2callback"

  ########################
  # Routes
  ########################

  get('/') do
    base_url = "https://accounts.google.com/o/oauth2/auth"
    state = SecureRandom.urlsafe_base64
    session[:state] = state
    scope = "profile"
    # storing state in session because we need to compare it in a later request
    @url = "#{base_url}?client_id=#{CLIENT_ID}&response_type=code&redirect_uri=#{CALLBACK_URL}&state=#{state}&scope=#{scope}"
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

  get('/oauth2callback') do
    code = params[:code]

    # compare the states to ensure the information is from who we think it is
    if session[:state] == params[:state]
      # send a POST
      response = HTTParty.post(
        "https://accounts.google.com/o/oauth2/token",
        :body => {
          code: code,
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          redirect_uri: CALLBACK_URL,
          grant_type: "authorization_code",
          },
        )
      session[:access_token] = response["access_token"]
      ## gets user info
      get_stuff = HTTParty.get("https://www.googleapis.com/plus/v1/people/me?access_token=#{response["access_token"]}")
      user_id = get_stuff["id"]
      name    = get_stuff["displayName"]

      unless $redis.get("user:#{user_id}")
        binding.pry
        new_user = NewUser.new(user_id, name)
        new_user.create_user
      end

    end
    redirect to("/")
  end

end
