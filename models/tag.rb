require 'sequel'
Sequel.connect("postgres://localhost:5432/wiki_app")

class Tag < Sequel::Model
  many_to_many(:versions)
end
