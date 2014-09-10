# WDI Wiki App #
## GA  August 2014, Project 1


[WDI wiki](http://ancient-inlet-1734.herokuapp.com/) is a Wiki app for compiling information about WDI. This app can have many users that can update and manage articles. Features include the ability to tag articles as well as become contributors to other participants articles.

This app was developed by Erica Kantor as a first project for a Web development Immersive at [General Assembly](http://generalassemb.ly). It is intended as a way for WDI classes to be able to share informtion and best practices amongst eachother.

###Technologies Used

- [Ruby](http://www.ruby-lang.org/en/) '2.1.2'
- [Sinatra](http://www.sinatrarb.com/) '1.4.5'
- [Redis ](http://redis.io/)'3.1.0'
- The Markdown converters  used were [redcarpet](https://github.com/vmg/redcarpet) '3.1.2' and [reverse_markdown](https://github.com/xijo/reverse_markdown) '0.5.1'
- [HTTParty](https://github.com/jnunemaker/httparty) '0.13.1'
- [diffy](https://github.com/samg/diffy) '3.0.6' for showing the differences between versions
- Google + API

### User Stories

- A user can browse all articles
- A user can sign in using google
- Once logged in a user can create articles using markdown
- A user can delete or edit any of their own artices
- A user can request access to edit articles they did not create
- A user can grant or deny another user access to editing their articles
- A user can search by article title or by tag
- A user can see older versions of an article and compare how it is different from the current version
