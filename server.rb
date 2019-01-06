require 'rubygems'
require 'bundler/setup'
require 'json'
require 'pp'
require 'sequel'
require 'mysql2'
require 'sinatra/base'
require 'sinatra_warden'
require 'erb'
#require 'rack/flash'

DB_NAME = ENV['DB_NAME'] || 'baby_namer'
DB_USERNAME =  ENV['DB_USERNAME'] || 'root'
DB_HOST =  ENV['DB_HOST'] || 'localhost'
DB_PASSWORD =  ENV['DB_PASSWORD'] || 'root'

DB = Sequel.connect(:adapter => 'mysql2', :host => DB_HOST, :user => DB_USERNAME,
    :password => DB_PASSWORD, :database => DB_NAME)

['models'].each do |dir|
  Dir[File.expand_path(File.dirname(__FILE__)) + "/#{dir}/*.rb"].each {|f| require f }
end

require "./warden_setup.rb"
class BabyNamer < Sinatra::Base
  set :port, 4000
  set :public_folder, File.dirname(__FILE__) + "/static"
  register Sinatra::Warden
  set :auth_template_renderer, :erb
  set :auth_failure_path, "/login"

  use Rack::Session::Cookie, :secret => (ENV['COOKIE_SECRET'] || 'ldkja8adj7sz6a')
  #use Rack::Flash, accessorize: [:error, :success]
  use Warden::Manager do |config|
    config.scope_defaults :default,
      strategies: [:password], 
      action: '/login'
    config.failure_app = self
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

  post "/create_account" do
    begin
      @user = User.create_user(
        params["user"]["email"],
        params["user"]["password"]
      )
      redirect "/"
    rescue
      @errors = $!.message
      erb :login, :layout => nil
    end
  end

  get "/" do
    authorize!
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

  post "/create_list" do
    parsed = JSON.parse(request.env["rack.input"].read)
    new_list = BabyList.create_from_list(parsed["name"], parsed["list"].split(/[\n,]/).map {|x| x.strip} )
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

  run! if app_file == $0
end