require './application_controller'
class App  < ApplicationController
  # Main page - can preview docs
  get('/') do
    @url = log_in_google
    @docs = get_by_params(what_to_query: 'document')
    render(:erb, :index)
  end

  # LOGOUT
  get('/logout') do
    session.clear
    redirect to('/')
  end

  get('/search') do
    page = params[:search].gsub(' ', '_')
    @result = params[:search]
    @doc = get_by_params(query_type: 'id', id: page.downcase, what_to_query: 'document')
    if @doc.length >= 1
      render(:erb, :search_results)
    elsif @doc.length < 1
      redirect to("/?search=#{params[:search]}")
    else
      redirect to("/documents/#{page}")
    end
  end

  get('/search/:tag') do
    @result = params[:tag]
    @doc =  get_by_params(query_type: 'compare to something', param1: params[:tag], param2: 'tags', what_to_query: 'document')
    render(:erb, :search_results)
  end

  get('/documents') do
    @url = log_in_google
    @first = 1
    @new_doc_list = get_by_params(what_to_query: 'document')
    @docs  = @new_doc_list.take(10)
    if params[:first]
      @docs = @new_doc_list.drop(params[:first].to_i - 1).take(10)
      @first = params[:first].to_i
    end
    # @pages = (@docs.length/10.0).ceil
    render(:erb, :browse)
  end

  # Create a new document - refers to document class
  get('/documents/new') do
    @create_new = true
    @tags = get_single_redis_item('article_tags')
    render(:erb, :create_doc)
  end

  # See a specific document - finds it by name
  get('/documents/:id_name') do
    @doc = get_by_params(query_type: 'single_doc', id: params[:id_name].downcase, what_to_query: 'document')
    if session[:current_user]
      @user_id = session[:current_user][:user_id]
    else
      @user_id = nil
    end
    @url = log_in_google
    if @doc.length > 0
      @can_edit = can_edit(@doc[0]['doc_id'])
    end
    render(:erb, :documents)
  end

  # See a specific document - and make changes
  get('/documents/:id_name/edit') do
    @edit = true
    @tags = get_single_redis_item('article_tags')
    @document = get_by_params(query_type: 'id', id: params[:id_name], what_to_query: 'document')
    @approved = approved(@document[0]['primary_user']['user_id'], session[:current_user][:user_id])
    @can_edit = can_edit(@document[0]['doc_id'])
    render(:erb, :create_doc)
  end

  get('/documents/:id_name/versions') do
    @url = log_in_google
    @document = get_by_params(query_type: 'id', id: params[:id_name], what_to_query: 'document')
    render(:erb, :see_versions)
  end

  get('/documents/:id_name/versions/:version_num') do
    @url = log_in_google
    @document = get_by_params(query_type: 'id', id: params[:id_name], what_to_query: 'document')
    @version = params[:version_num]
    render(:erb, :difference)
  end

  # User page wher user can see all their documents
  get('/users/:user_id') do
    @approved = approved(params[:user_id], session[:current_user][:user_id])
    @editable_docs =  get_by_params(query_type: 'compare to something', param1: params[:user_id], param2: 'content_users', param3: 'user_id', what_to_query: 'document')
    @user_documents = get_by_params(query_type: 'compare to primary', param1: params[:user_id], what_to_query: 'document')
    @user = get_single_redis_item(params[:user_id], 'user')
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
    usr =  get_single_redis_item(session[:current_user][:user_id], 'user')
    match = find_match(param1: params[:title].downcase, what_to_query: 'document')
    if match
      redirect to('/documents/new?title_match=true')
    else
      user_array = params[:user_input_tag].split(',')
      tag_array = get_single_redis_item('article_tags')
      user_array.each do |x|
        tag_array.push(x.strip)
        params[:tags].push(x.strip)
      end
      tag_array.delete('')
      params[:tags].delete('')
      $redis.set('article_tags', tag_array.uniq.to_json)
      new_doc = Document.new(usr, params[:title].downcase, content, $redis.get('doc_counter'), params[:tags])
      new_doc.create_doc
      $redis.incr('doc_counter')
      redirect to('/')
    end
  end

  # Remove a document that you created
  delete('/documents/:doc_id') do
    $redis.del("document:#{params[:doc_id]}")
    redirect to('/')
  end

  # edit user name
  put('/users/:user_id/:doc_id') do
    user_to_get = get_single_redis_item(params[:user_id], 'user')
    user_to_get['pending_requests'].push(edit_request_hash(session[:current_user][:user_id], params[:doc_id]))
    user_key = "user:#{params[:user_id]}"
    $redis.set(user_key, user_to_get.to_json)
    redirect to('/')
  end

  # Edit a document
  put('/documents/:id_name') do
    user_array = params[:user_input_tag].split(',')
    tag_array = get_single_redis_item('article_tags')
    user_array.each do |x|
      tag_array.push(x.strip)
      params[:tags].push(x.strip)
    end
    $redis.set('article_tags', tag_array.uniq.to_json)
    content = render(:markdown, params[:content])
    doc_to_get  = get_single_redis_item(params[:doc_id], 'document')
    doc_to_get['tags'] = params[:tags]
    doc_to_get['doc_versions'].push(create_version_hash(content, session[:current_user], params[:doc_id]))
    doc_key = "document:#{params[:doc_id]}"
    $redis.set(doc_key, doc_to_get.to_json)
    redirect to("/documents/#{params[:id_name].gsub(' ', '_')}")
  end

  put('/documents/:doc_id/permission/:request_info') do
    doc_to_get  = get_single_redis_item(params[:doc_id], 'document')
    doc_to_get['content_users'].push(user_id: params[:request_info])
    doc_key = "document:#{params[:doc_id]}"
    $redis.set(doc_key, doc_to_get.to_json)
    user = get_single_redis_item(session[:current_user][:user_id], 'user')
    user['pending_requests'].delete_if { |x| x['request_user_id'] == params[:request_info] }
    user_key = "user:#{session[:current_user][:user_id]}"
    $redis.set(user_key, user.to_json)
    redirect back
  end

  put('/documents/deny/:request_info') do
    user = get_single_redis_item(session[:current_user][:user_id], 'user')
    user['pending_requests'].delete_if { |x| x['request_user_id'] == params[:request_info] }
    user_key = "user:#{session[:current_user][:user_id]}"
    $redis.set(user_key, user.to_json)
    redirect back
  end

  get('/oauth2callback') do
    session[:current_user] = {}
    code = params[:code]
    # compare the states to ensure the information is from who we think it is
    if session[:state] == params[:state]
      # send a POST
      response = HTTParty.post(
        'https://accounts.google.com/o/oauth2/token',
        body: {
          code: code,
          client_id: ENV['CLIENT_ID'],
          client_secret: ENV['CLIENT_SECRET'],
          redirect_uri: CALLBACK_URL,
          grant_type: 'authorization_code'
        }
        )
      session[:current_user][:access_token] = response['access_token']
      ## gets user info
      get_stuff = HTTParty.get("https://www.googleapis.com/plus/v1/people/me?access_token=#{response['access_token']}")
      user_id = get_stuff['id']
      name    = get_stuff['displayName']
      gender  = get_stuff['gender']
      session[:current_user][:user_id] = user_id
      session[:current_user][:name] = name
      session[:current_user][:gender] = gender
      unless $redis.get("user:#{user_id}")
        new_user = NewUser.new(user_id, name)
        new_user.create_user
      end

    end
    redirect to('/')
  end
end
