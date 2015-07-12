require 'rubygems'
require 'bundler/setup'
require 'json'
require 'pp'
require 'sequel'
require 'mysqlplus'
require 'sinatra'
require 'erb'
require 'thin'

['models'].each do |dir|
  Dir[File.expand_path(File.dirname(__FILE__)) + "/#{dir}/*.rb"].each {|f| require f }
end

DB_NAME = 'baby_names'
DB_USERNAME = 'root'
DB_HOST = 'localhost'
DB_PASSWORD = ''

set :port, 4000

DB = Sequel.connect(:adapter => 'mysql', :host => DB_HOST, :user => DB_USERNAME,
  :password => DB_PASSWORD, :database => DB_NAME)
  
