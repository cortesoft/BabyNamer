require 'rake'
begin
  load File.expand_path(File.dirname(__FILE__) + '/server.rb')
rescue LoadError
end

namespace :puma do
  desc "Starts the BabyName server"
  task :start do
    system("pumactl -F puma.rb start")
  end

  desc "Stops the BabyName server"
  task :stop do
    system("pumactl -F puma.rb stop")
  end

  desc "Restart BabyName server"
  task :restart => [:stop, :start]

  desc "Check BabyName status"
  task :status do
    system("pumactl -F puma.rb status")
  end
end

namespace :baby do
  desc "Create the default lists if needed"
  task :create_defaults do
    BabyList.create_defaults
  end
end

namespace :db do

  desc "Create the DB"
  task :create do
    puts "Using mysql root to create database #{DB_NAME}:"
    puts `mysql -h #{DB_HOST} -u root -p -e "CREATE DATABASE IF NOT EXISTS #{DB_NAME}; GRANT ALL ON #{DB_NAME}.* TO '#{DB_USERNAME}' IDENTIFIED BY '#{DB_PASSWORD}';"`
  end

  desc "Migrate the DB"
  task :migrate, [:to_rev] do |t, args|
    Sequel.extension :migration
    if args[:to_rev]
      Sequel::Migrator.run(DB, "db", args[:to_rev].to_i)
    else
      Sequel::Migrator.run(DB, "db")
    end
  end

  desc "Dump the DB to file"
  task :dump, [:outfile, :gzip] do |t, args|
    filepath = File.expand_path(args[:outfile])
    puts "Dumping database '#{DB_NAME}' to #{filepath}"
    puts `mysqldump -h #{DB_HOST} -u #{DB_USERNAME} -p#{DB_PASSWORD} #{DB_NAME} #{args[:gzip] ? "| gzip" : ""} > #{filepath}`
  end
end
