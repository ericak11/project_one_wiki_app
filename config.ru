require 'rubygems'
require 'bundler'

require 'sinatra/base'
require 'redis'
require 'json'
require 'uri'
require 'httparty'
require 'redcarpet'
require 'pry' if ENV['RACK_ENV'] == 'development'
require 'date'
require 'diffy'
require 'reverse_markdown'
# takes care of that!
# loading up all the gems that i had to previously write require for
Bundler.require(:default, ENV["RACK_ENV"].to_sym)

require './app'

run App
