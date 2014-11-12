require 'sequel'
Sequel.connect("postgres://localhost:5432/wiki_app")

class Version < Sequel::Model
  many_to_many(:tags)
  many_to_one(:document)
  many_to_one(:user)
end
