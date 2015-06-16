# test_helper.rb
ENV['RACK_ENV'] = 'test'
require 'minitest/autorun'
require 'rack/test'

require './app/api.rb'

def api_for(resource)
  config = YAML.load File.read('config/child_sponsorship.yml')
  "/api/#{config[:api_version]}#{resource}"
end

# def setup
#   jeff = User.new name:"Jeff"
# end

def last_response_data
  begin
    JSON.parse(last_response.body, { symbolize_names: true })
  rescue JSON::ParserError => e
    {}
  end
end
