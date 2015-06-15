require 'sinatra/activerecord/rake'
require 'sinatra/activerecord'
require 'sinatra/activerecord/rake'
require "./app/api"

$:.unshift File.expand_path("./app/", __FILE__)
require 'rake/testtask'

desc "Load the environment"
task :environment do
  env = ENV["SINATRA_ENV"] || "test"
  databases = YAML.load_file("./config/database.yml")
  ActiveRecord::Base.establish_connection(databases[env])
end

namespace :db do
  desc "Migrate the database"
  task(:migrate => :environment) do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate("db/migrate")
  end
end

# namespace :db do
#   desc "migrate your database"
#   task :migrate do
#     require 'bundler'
#     Bundler.require
#     require './config/environment'
#     ActiveRecord::Migrator.migrate('db/migrate')
#   end
# end

# namespace :db do
#   task :load_config do
#     require "./app/api"
#   end
# end

task :console do
  system "./script/console"
end

task :server do
  system "bundle exec rackup -p 4567"
end

Rake::TestTask.new do |t|
  t.pattern = "test/**/*_test.rb"
  t.pattern = "test/**/test_*.rb"
end

task default: :test