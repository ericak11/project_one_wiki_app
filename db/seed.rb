require 'sequel'
require 'pry'
require_relative '../models/document'
require_relative '../models/permission'
require_relative '../models/tag'
require_relative '../models/user'
require_relative '../models/version'

DB = Sequel.connect("postgres://localhost/wiki_app")

d1 = Document.create({title: "Sample 1"})
d2 = Document.create({title: "Sample 2"})
d3 = Document.create({title: "Sample 3"})

u1 = User.create({user_name: "Erica", google_id: 12345})

t1 = Tag.create({tag_name: "Ruby"})
t2 = Tag.create({tag_name: "Rails"})


v1 = Version.new({content:"Hello this is sample text"})

v1.user_id(u1)
v1.add_document(d1)
v1.add_tag(t1)
v1.add_tag(t2)

v1.save


