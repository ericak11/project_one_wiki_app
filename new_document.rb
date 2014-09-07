require 'date'
require 'redcarpet'
# require 'pry'

class Document
  attr_reader :primary_user, :doc_id
  attr_accessor :doc_content, :doc_name, :content_users
  @@doc_versions = []
  def initialize(primary_user, doc_name, doc_content, doc_id)
    @primary_user = primary_user
    @doc_name = doc_name
    @doc_content = doc_content
    @doc_id = doc_id
    @content_users = []
    $redis.setnx("doc_version:#{doc_id}", 0)
  end

  def create_doc_hash
    add_version(primary_user)
    doc_hash = {
      primary_user: primary_user,
      doc_name: doc_name,
      doc_id: doc_id,
      doc_versions: @@doc_versions,
      content_users: content_users,
    }
    doc_hash
  end

  def add_version(editor)
    version_hash = {
      doc_version: $redis.get("doc_version:#{doc_id}"),
      doc_content: doc_content,
      create_date: DateTime.now,
      edit_made_by: editor,
    }
    $redis.incr("doc_version:#{doc_id}")
    @@doc_versions.push(version_hash)
  end

  def create_doc
    doc_key = "document:#{doc_id}"
    $redis.set(doc_key, create_doc_hash.to_json)
  end


  # def edit_doc(id)
  #    = JSON.parse($redis.get(id))
  #   doc_key = "document:#{doc_id}"
  #   $redis.set(doc_key, create_doc_hash.to_json)
  # end

  # def add_content_user

  # end

end
