require 'sinatra/base'
require 'redis'
require 'json'
require 'uri'
require 'httparty'
require 'redcarpet'
require 'pry' if ENV["RACK_ENV"] == "development"
require 'date'
require 'diffy'
require 'reverse_markdown'
require_relative './new_user'
require_relative './new_document'
class App < Sinatra::Base
binding.pry

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
    $redis.setnx("doc_counter", 0)
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
  # CALLBACK_URL  = "http://ancient-inlet-1734.herokuapp.com/oauth2callback"

  ########################
  # Routes
  ########################

  # Main page - can preview docs
  get('/') do
    @url = log_in_google
    @docs = get_documents
    render(:erb, :index)
  end

  # LOGOUT
  get('/logout') do
    session.clear
    redirect to ('/')
  end

  get ('/search') do
    page = params[:search].gsub(" ", "_")
    redirect to ("/documents/#{page}")
  end

  get('/documents') do
    @docs = get_documents
    @pages = (@docs.length/10.0).ceil
    render(:erb, :browse)
  end

  # Create a new document - refers to document class
  get('/documents/new') do
    @create_new = true
    render(:erb, :create_doc)
  end

  # See a specific document - finds it by name
  get('/documents/:id_name') do
    @url = log_in_google
    @doc = get_documents(params[:id_name].downcase)
    render(:erb, :documents)
  end

  # See a specific document - and make changes
  get('/documents/:id_name/edit') do
    @edit = true
    @document = get_documents(params[:id_name])
    binding.pry
    if @document[0]["primary_user"]["user_id"] == session[:user_id]
      @approved = true
    end
    render(:erb, :create_doc)
  end

  get('/documents/:id_name/versions') do
    @document = get_documents(params[:id_name])
    render(:erb, :see_versions)
  end

  get('/documents/:id_name/versions/:version_num') do
    @document = get_documents(params[:id_name])
    @version = params[:version_num]
    render(:erb, :difference)
  end

  # User page wher user can see all their documents
  get('/users/:user_id') do
    @user_documents = get_users_doc(params[:user_id])
    render(:erb, :user_page)
  end

  # User page where user can edit personal info/permissions
  get('/users/:user_id/edit') do
    if params[:change]
      @change_name = true
    end
    render(:erb, :user_permissions)
  end

  # Creates a new document on redis
  post('/documents') do
    content = render(:markdown, params[:content])
    usr = JSON.parse($redis.get("user:#{session[:user_id]}"))
    match = parse_JSON_for_match(params[:title].downcase)
    if match
      redirect to ("/documents/new?title_match=true")
    else
      new_doc = Document.new(usr, params[:title].downcase, content, $redis.get('doc_counter'))
      new_doc.create_doc
      $redis.incr('doc_counter')
      redirect to ('/')
    end
  end

  # Remove a document that you created
  delete('/documents/:doc_id') do
    $redis.del("document:#{params[:doc_id]}")
    redirect to ("/")
  end

  # edit user name
  put('/users/:user_id') do

  end

  # Edit a document
  put('/documents/:id_name') do
    content = render(:markdown, params[:content])
    doc_to_get  = JSON.parse($redis.get("document:#{params[:doc_id]}"))
    doc_to_get["doc_versions"].push(create_version_hash(content, session[:user], params[:doc_id]))
    doc_key = "document:#{params[:doc_id]}"
    $redis.set(doc_key, doc_to_get.to_json)
    redirect to ("/documents/#{params[:id_name].gsub(" ", "_")}")
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
      session[:user_id] = user_id
      session[:user] = {
          user_id: user_id,
          name: name,
      }
      unless $redis.get("user:#{user_id}")
        new_user = NewUser.new(user_id, name)
        new_user.create_user
      end

    end
    redirect back
  end


  def get_documents(id=nil)
    @documents = []
    $redis.keys('*document*').each do |key|
      doc = JSON.parse($redis.get(key))
      if id
        if doc["doc_name"].gsub(" ", "_").match(id)
          @documents << doc
        end
      else
        @documents << doc
      end
    end
    @documents
  end

  def get_users_doc(user_id)
    @user_docs = []
    $redis.keys('*document*').each do |key|
      doc = JSON.parse($redis.get(key))
      if user_id == doc["primary_user"]["user_id"]
        @user_docs.push(doc)
      end
    end
    @user_docs
  end

  def parse_JSON_for_match(item_to_match)
    @match = nil
    $redis.keys('*document*').each do |key|
      doc = JSON.parse($redis.get(key))
      if item_to_match == doc["doc_name"]
        @match = true
      end
    end
    @match
  end

  def create_version_hash(doc_content, editor, doc_id)
    version_hash = {
    doc_version: $redis.get("doc_version:#{doc_id}"),
    doc_content: doc_content,
    create_date: DateTime.now,
    edit_made_by: editor,
    }
    $redis.incr("doc_version:#{doc_id}")
    version_hash
  end

  def log_in_google
    base_url = "https://accounts.google.com/o/oauth2/auth"
    state = SecureRandom.urlsafe_base64
    session[:state] = state
    scope = "profile"
    # storing state in session because we need to compare it in a later request
    url_for_login = "#{base_url}?client_id=#{CLIENT_ID}&response_type=code&redirect_uri=#{CALLBACK_URL}&state=#{state}&scope=#{scope}"
    url_for_login
  end

end
