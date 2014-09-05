require 'date'

class Document
  attr_reader :user, :doc_id
  attr_accessor :doc_content, :doc_name,
  def initialize(user, doc_name, doc_content, doc_id)
    @user = user
    @doc_name = doc_name
    @doc_content = doc_content
    @doc_id = doc_id
    $redis.setnx("doc_version:#{doc_id}", 0)
  end

  def create_doc_hash
    new_doc = {
      user: user,
      doc_name: doc_name,
      doc_content: doc_content,
      doc_id: doc_id,
      doc_version: $redis.get("doc_version:#{doc_id}"),
      create_date: DateTime.now,
    }
    new_doc
  end

  def create_doc
    doc_key = "document:#{doc_id}"
    $redis.set(doc_key, create_doc_hash.to_json)
  end

  def edit_doc
    $redis.incr("doc_version:#{doc_id}")
    edit_doc_hash = {
      user: user,
      doc_name: doc_name,
      doc_content: doc_content,
      doc_id: doc_id,
      doc_version: $redis.get("doc_version:#{doc_id}"),
      edit_date: DateTime.now,
    }
    doc_key = "document:#{doc_id}"
    $redis.set(doc_key, edit_doc_hash.to_json)
  end


end
