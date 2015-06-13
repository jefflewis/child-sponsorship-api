require 'sinatra/activerecord/rake'

$:.unshift File.expand_path("./app/", __FILE__)
require 'rake/testtask'

namespace :db do
  task :load_config do
    require "./app/api"
  end
end

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