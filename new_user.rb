class NewUser
  attr_reader :name, :user_id
  attr_accessor :documents
  def initialize(user_id, name)
    @user_id = user_id
    @name = name
    @documents = []
  end

  def create_user_hash
    new_user = {
      user_id: user_id,
      name: name,
      documents: documents,
    }
    new_user
  end

  def create_user
    user_key = "user:#{user_id}"
    $redis.set(user_key, create_user_hash.to_json)
  end



end
