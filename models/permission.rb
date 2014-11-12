require 'sequel'
Sequel.connect("postgres://localhost:5432/wiki_app")

class Permission < Sequel::Model

end
