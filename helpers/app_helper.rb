module AppHelper
  if ENV['RACK_ENV'] == 'development'
    CALLBACK_URL  = 'http://127.0.0.1:3000/oauth2callback'
  else
    # HEROKU
    CALLBACK_URL  = 'http://ancient-inlet-1734.herokuapp.com/oauth2callback'
  end
  #####################
  # ## METHODS ########
  #####################

  def get_by_params(options = {})
    @documents = []
    $redis.keys("*#{options[:what_to_query]}*").each do |key|
      doc = get_single_redis_item(key)
      if options[:query_type] == 'id'
        @documents << doc if doc['doc_name'].gsub(' ', '_') == (options[:id])
      elsif options[:query_type] == 'single_doc'
        @documents << doc if doc['doc_name'].gsub(' ', '_') == options[:id]
      elsif options[:query_type] == 'compare to primary'
        @documents << doc if options[:param1] == doc['primary_user']['user_id']
      elsif options[:query_type] == 'compare to something'
        doc[options[:param2]].each do |x|
          case
          when options[:param3]
            @search_params = options[:param1] == x[options[:param3]]
          when !options[:param3]
            @search_params = options[:param1] == x
          end
           @documents << doc if @search_params
        end
      else
        @documents << doc
      end
    end
    @documents
  end

  def get_single_redis_item(item_id, what_to_parse = nil)
    if what_to_parse
      JSON.parse($redis.get("#{what_to_parse}:#{item_id}"))
    else
      JSON.parse($redis.get(item_id))
    end
  end

  def log_in_google
    base_url = 'https://accounts.google.com/o/oauth2/auth'
    state = SecureRandom.urlsafe_base64
    session[:state] = state
    scope = 'profile'
    # storing state in session because we need to compare it in a later request
    url_for_login = "#{base_url}?client_id=#{ENV['CLIENT_ID']}&response_type=code&redirect_uri=#{CALLBACK_URL}&state=#{state}&scope=#{scope}"
    url_for_login
  end

  ##### Boolean Methods #######
  def approved(item1, item2)
    is_approved = true if item1 == item2
    is_approved
  end

  def can_edit(id_num)
    is_approved = nil
    doc = get_single_redis_item(id_num, 'document')
    doc['content_users'].each do |x|
      is_approved = true if x['user_id'] == session[:current_user][:user_id]
    end
    is_approved
  end

  def find_match(options = {})
    match = nil
    $redis.keys("*#{options[:what_to_query]}*").each do |key|
      doc = get_single_redis_item(key)
      match = true if options[:param1] == doc['doc_name']
    end
    match
  end

  ##### creating Hashes #######
  def edit_request_hash(user_id, doc_id)
    request_hash = {
      request_user_id: user_id,
      request_date: DateTime.now,
      doc_requested_for: doc_id
    }
    request_hash
  end

  def create_version_hash(doc_content, editor, doc_id)
    version_hash = {
      doc_version: $redis.get("doc_version:#{doc_id}"),
      doc_content: doc_content,
      create_date: DateTime.now,
      edit_made_by: editor
    }
    $redis.incr("doc_version:#{doc_id}")
    version_hash
  end
end
