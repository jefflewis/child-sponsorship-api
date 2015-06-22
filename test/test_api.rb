require './test/test_helper'

module ChildSponsorship

  class ApiTest < MiniTest::Test

    include Rack::Test::Methods

    def app
      Api
    end

    def setup
      create_users
      create_children
    end

    def teardown
      delete_chidren
      delete_users
    end

    def get_token(user)
      post api_for('/login'), { :email => user.email,
                                :password => user.password }
      last_response_data['token']
    end

    def test_root
      get api_for '/'
      assert last_response.ok?
      assert_equal "Child Sponsorship API is up and running".to_json, last_response.body
    end

    def test_post_login
      assert_equal @admin_user.email, 'test@test.com'
      assert_equal @admin_user.password, 'foobar'
      post api_for('/login'), { :email => @admin_user.email,
                                :password => @admin_user.password }.to_json
      token1 = last_response_data[:token]
      refute_nil token1, "Token returned nil"
      assert_equal 200, last_response.status
      # assert_match /^[a-f0-9]{32}$/, token1
      # Test if a second request generates a new token
      post api_for('/login'), { :email => @admin_user.email,
                                :password => @admin_user.password }.to_json
      token2 = last_response_data[:token]
      refute_equal token1, token2
      # Invalid credentials do not provide a token
      post api_for('/login'), { :email      => 'test@test.com',
                                :password   => 'badword' }.to_json
      assert_equal 401, last_response.status
      # Not found returned if email not found for suer
      post api_for('/login'), { :email      => 'bad@email',
                                :password   => 'badword' }.to_json
      assert_equal 404, last_response.status
    end

    def test_admin_access
      # auth not required, Admin user
      get api_for('/auth-not-required')
      assert_equal 200, last_response.status
      assert_equal last_response_data, { :some_key => 'some_value' }
      # auth-required, Admin user
      post api_for('/login'), { :email => @admin_user.email,
                                :password => @admin_user.password }.to_json
      token = last_response_data[:token]
      refute_nil token
      get api_for("/auth-required?token=#{token}"), { token: token }.to_json
      assert_equal 200, last_response.status
      assert_equal last_response_data, { :some_private_key => 'some_private_value' }
      # GET user
      get api_for("/user?token=#{token}"), { token: token }.to_json
      assert_equal 200, last_response.status
      assert_equal @admin_user.to_json, last_response_data.to_json
      # Test non-admin user access
      post api_for('/login'), { :email     => @reg_user.email,
                                :password  => @reg_user.password }.to_json
      token = last_response_data[:token]
      # auth not required, non-admin user
      get api_for('/auth-not-required'), { token: token }
      assert_equal 200, last_response.status
      assert_equal last_response_data, { :some_key => 'some_value' }
      # auth-required, non-admin user
      get api_for("/auth-required?token=#{token}"), { token: token }
      assert_equal 403, last_response.status
      # Delete invalidates tokens
      get api_for('/logout'), { token: token }
      get api_for("/auth-required?token=#{token}")
      assert_equal 403, last_response.status
      # Delete with invalid token throws an error
      get api_for('/logout'), { token: 'badtoken' }
      assert_equal 404, last_response.status
    end

    def test_signup
      testUser = { :email     => "testing3@test.com",
                   :password  => "foobar"}.to_json
      post api_for('/signup'), testUser
      token = last_response_data[:token]
      refute_nil token, 'Token should not be nil'
      assert_equal 200, last_response.status, 'Post should succeed'
      user = User.find_by(email: "testing3@test.com")
      refute_nil user, 'User should not be nil'
      user.delete
    end

    def test_all_users
      post api_for('/login'), { :email => @admin_user.email,
                                :password => @admin_user.password }.to_json
      token = last_response_data[:token]
      refute_nil token
      get api_for('/users'), { token: token }
      assert last_response_data, User.all.to_json
    end

    def test_admin_get_single_user
      user = User.first
      refute_nil user
      post api_for('/login'), { :email =>     @admin_user.email,
                                :password =>  @admin_user.password }.to_json
      assert_equal 200, last_response.status
      token = last_response_data[:token]
      refute_nil token
      get api_for("/users/#{user.id}"), { token: token }
      assert_equal 200, last_response.status
      refute_nil last_response_data
      assert_equal last_response_data.to_json, user.to_json
    end

    def test_get_user
      post api_for('/login'), { :email => @reg_user.email, :password => @reg_user.password }.to_json
      assert_equal 200, last_response.status
      token = last_response_data[:token]
      refute_nil token
      get api_for('/user'), { token: token }
      assert_equal 200, last_response.status
      assert_equal @reg_user.to_json, last_response_data.to_json
    end

    def test_get_all_children
      get api_for('/children')
      assert Child.all.to_json, last_response_data
    end

    def test_get_single_child
      child = Child.first
      refute_nil child
      get api_for("/children/#{child.id}")
      assert_equal 200, last_response.status
      refute_nil last_response_data
      assert_equal child.to_json, last_response_data.to_json
    end

    def test_create_child
      child = {
        name: "Jonah",
        description: "Young boy",
        user_id: @admin_user.id
      }
      post api_for('/login'), { :email => @admin_user.email,
                                :password => @admin_user.password }.to_json
      token = last_response_data[:token]
      refute_nil token
      post api_for('/children'), (child.merge({ token: token })).to_json
      assert_equal 200, last_response.status
      child = nil
      child = Child.find_by(name: "Jonah")
      refute_nil child
      assert_equal child.to_json, last_response_data.to_json
      child.delete
    end

    def test_delete_user
      post api_for('/login'), { :email =>     @admin_user.email,
                                :password =>  @admin_user.password }.to_json
      assert_equal 200, last_response.status
      token = last_response_data[:token]
      refute_nil token
      id = @admin_user.id
      delete api_for("/users/#{id}"), { token: token }
      assert_equal 200, last_response.status
      user = User.find_by(id: id)
      assert_nil user
      assert_equal last_response_data, { message: "User: #{id} deleted" }
    end

    def test_delete_child
      post api_for('/login'), { :email =>     @admin_user.email,
                                :password =>  @admin_user.password }.to_json
      assert_equal 200, last_response.status
      token = last_response_data[:token]
      refute_nil token
      id = Child.first.id
      delete api_for("/children/#{id}"), { token: token }
      assert_equal 200, last_response.status
      child = Child.find_by(id: id)
      assert_nil child
      assert_equal last_response_data, { message: "Child: #{id} deleted" }
    end
  end
end
