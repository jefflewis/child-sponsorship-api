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


def create_users
  @admin_user = User.new(name:                  'jeff',
                         password:              'foobar',
                         password_confirmation: 'foobar',
                         email:                 'test@test.com',
                         access:                10)
  @admin_user.save

  @reg_user = User.new( name:                  'user',
                        password:              'foobar',
                        password_confirmation: 'foobar',
                        email:                 'test2@test.com',
                        access:                1)
  @reg_user.save
end

def create_children

  @child1 = Child.new(
    name: "Harriet",
    description: "Young Girl",
    user_id: @admin_user.id
  )
  @child1.save

  @child2 = Child.new(
    name: "Harriet",
    description: "Young Girl",
    user_id: @admin_user.id
  )
  @child2.save

  @child3 = Child.new(
    name: "Harriet",
    description: "Young Girl",
    user_id: @reg_user.id
  )
  @child3.save

  @child4 = Child.new(
    name: "Harriet",
    description: "Young Girl",
    user_id: @reg_user.id
  )
  @child4.save
end

def delete_chidren
  Child.destroy_all
end

def delete_users
  User.destroy_all
end



