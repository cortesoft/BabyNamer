require 'rubygems'
require 'bundler/setup'
require 'json'
require 'pp'
require 'sequel'
require 'mysql2'
require 'sinatra/base'
require 'erb'
require 'sinatra/flash'
require 'warden'

DB_NAME = ENV['DB_NAME'] || 'baby_namer'
DB_USERNAME =  ENV['DB_USERNAME'] || 'root'
DB_HOST =  ENV['DB_HOST'] || 'localhost'
DB_PASSWORD =  ENV['DB_PASSWORD'] || 'root'

DB = Sequel.connect(:adapter => 'mysql2', :host => DB_HOST, :user => DB_USERNAME,
    :password => DB_PASSWORD, :database => DB_NAME)

['models'].each do |dir|
  Dir[File.expand_path(File.dirname(__FILE__)) + "/#{dir}/*.rb"].each {|f| require f }
end
BabyList.create_defaults

require "./warden_setup.rb"
class BabyNamer < Sinatra::Base
  set :port, 4000
  set :public_folder, File.dirname(__FILE__) + "/static"
  use Rack::Session::Cookie, :secret => (ENV['COOKIE_SECRET'] || 'ldkja8adj7sz6a')
  register Sinatra::Flash

  #use Rack::Flash, accessorize: [:error, :success]
  use Warden::Manager do |config|
    config.serialize_into_session{|user| user.id }
    config.serialize_from_session{|id| User[id] }
    config.scope_defaults :default,
      strategies: [:password], 
      action: '/unauthenticated'
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
        "name2" => name2,
        "am_owner" => baby_list.user_id == current_user.id
      })
    end

    def warden
      env['warden']
    end

    def current_user
      warden.user
    end

    def check_list(list)
      unless list.can_vote?(current_user)
        halt 403, "You do not have access to this list"
      end
    end
  end

  get "/login" do
    erb :login, :layout => nil
  end

  post "/login" do
    warden.authenticate!
    flash[:success] = "Successfully logged in"
    if session[:return_to].nil?
      redirect '/'
    else
      redirect session[:return_to]
    end
  end

  get '/logout' do
    warden.logout
    flash[:success] = 'Successfully logged out'
    redirect '/'
  end

  post '/unauthenticated' do
    session[:return_to] = env['warden.options'][:attempted_path] if session[:return_to].nil?

    # Set the error and use a fallback if the message is not defined
    flash[:error] = env['warden.options'][:message] || "You must log in"
    redirect '/login'
  end

  post "/create_account" do
    begin
      user = User.create_user(
        params["user"]["email"],
        params["user"]["password"]
      )
      warden.set_user(user)
      redirect "/"
    rescue
      flash.now[:error] = $!.message
      erb :login, :layout => nil
    end
  end

  get "/" do
    warden.authenticate!
    @my_baby_lists = current_user.my_lists
    @public_baby_lists = 
      (@my_baby_lists +
      BabyList.where(:cloneable => true).all).uniq.sort_by(&:name)
    erb :index
  end

  get "/display_choice/:id" do
    warden.authenticate!
    baby_list = BabyList[params[:id]]
    check_list(baby_list)
    choose_two_names(baby_list)
  end

  post "/duplicate_list/:id" do
    warden.authenticate!
    baby_list = BabyList[params[:id]]
    unless baby_list.cloneable
      halt 403, "Can't clone that list"
    end
    parsed = JSON.parse(request.env["rack.input"].read)
    new_list = baby_list.duplicate_list(parsed["name"], current_user)
    render_as_json({"id" => new_list.id})
  end

  post "/create_list" do
    warden.authenticate!
    parsed = JSON.parse(request.env["rack.input"].read)
    new_list = BabyList.create_from_list(
      current_user,
      parsed["name"],
      parsed["list"].split(/[\n,]/).map {|x| x.strip},
      parsed["cloneable"]
    )
    render_as_json({"id" => new_list.id})
  end

  get "/results/:id" do
    warden.authenticate!
    baby_list = BabyList[params[:id]]
    check_list(baby_list)
    ratings = baby_list.baby_ratings_dataset.eager(:baby_name).order(:rating).all.reverse
    res = "<table><tr><th>Name</th><th>Rating</th><th>Num Matchups</th></tr>" +
    ratings.map {|r|
      "<tr><td>#{r.name}</td><td>#{r.rating}</td><td>#{r.count}</td></tr>"
    }.join("\n") + "</table>"
    render_as_json({"html" => res})
  end

  post "/invite_email/:id" do
    warden.authenticate!
    baby_list = BabyList[params[:id]]
    if baby_list.user_id == current_user.id
      parsed = JSON.parse(request.env["rack.input"].read)
      message = baby_list.add_as_voter(parsed["email"])
    else
      message = "You can only invite people to lists you create"
    end
    render_as_json({"message" => message})
  end

  post "/chose/:id" do
    warden.authenticate!
    baby_list = BabyList[params[:id]]
    check_list(baby_list)
    parsed = JSON.parse(request.env["rack.input"].read)
    baby_list.update_winner(parsed["winner"], parsed["loser"], current_user)
    choose_two_names(baby_list)
  end

  post "/chose_tie/:id" do
    warden.authenticate!
    baby_list = BabyList[params[:id]]
    check_list(baby_list)
    parsed = JSON.parse(request.env["rack.input"].read)
    baby_list.update_tie(parsed["name1"], parsed["name2"], current_user)
    choose_two_names(baby_list)
  end

  run! if app_file == $0
end