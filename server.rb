require 'rubygems'
require 'bundler/setup'
require 'json'
require 'pp'
require 'sequel'
require 'mysqlplus'
require 'sinatra'
require 'erb'
require 'thin'

DB_NAME = 'baby_names'
DB_USERNAME = 'root'
DB_HOST = 'localhost'
DB_PASSWORD = ''

set :port, 4000

set :public_folder, File.dirname(__FILE__) + "/static"

DB = Sequel.connect(:adapter => 'mysql', :host => DB_HOST, :user => DB_USERNAME,
  :password => DB_PASSWORD, :database => DB_NAME)

['models'].each do |dir|
  Dir[File.expand_path(File.dirname(__FILE__)) + "/#{dir}/*.rb"].each {|f| require f }
end

helpers do
  def render_as_json(data, status_code = 200)
    [status_code, {'Content-Type' => "application/json"},
      data.is_a?(String) ? data : data.to_json]
  end
  
  def choose_two_names(baby_list)
    name1, name2 = baby_list.two_names
    render_as_json({
      "list_title" => baby_list.name,
      "name1" => name1,
      "name2" => name2
    })
  end
end

get "/" do
  @baby_lists = BabyList.order(:name).all
  erb :index
end

get "/display_choice/:id" do
  baby_list = BabyList[params[:id]]
  choose_two_names(baby_list)
end

post "/duplicate_list/:id" do
  baby_list = BabyList[params[:id]]
  parsed = JSON.parse(request.env["rack.input"].read)
  new_list = baby_list.duplicate_list(parsed["name"])
  render_as_json({"id" => new_list.id})
end

get "/results/:id" do
  baby_list = BabyList[params[:id]]
  ratings = baby_list.baby_ratings_dataset.eager(:baby_name).order(:rating).all.reverse
  res = "<table><tr><th>Name</th><th>Rating</th><th>Count</th></tr>" +
  ratings.map {|r|
    "<tr><td>#{r.name}</td><td>#{r.rating}</td><td>#{r.count}</td></tr>"
  }.join("\n") + "</table>"
  render_as_json({"html" => res})
end

post "/chose/:id" do
  baby_list = BabyList[params[:id]]
  parsed = JSON.parse(request.env["rack.input"].read)
  baby_list.update_winner(parsed["winner"], parsed["loser"])
  choose_two_names(baby_list)
end

post "/chose_tie/:id" do
  baby_list = BabyList[params[:id]]
  parsed = JSON.parse(request.env["rack.input"].read)
  baby_list.update_tie(parsed["name1"], parsed["name2"])
  choose_two_names(baby_list)
end