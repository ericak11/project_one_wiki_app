require 'sequel'
Sequel.connect("postgres://localhost:5432/wiki_app")

class Document < Sequel::Model
  many_to_many(:permissions)
  one_to_many(:versions)
end
