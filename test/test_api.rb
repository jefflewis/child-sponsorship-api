require './test/test_helper'

module ChildSponsorship

  class ApiTest < MiniTest::Test

    include Rack::Test::Methods

    def app
      Api
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

    def get_token(user)
      post api_for('/login'), { 'email' => user.email,
                                'password' => user.password }
      last_response_data['token']
    end

    def test_root
      get api_for '/'
      assert last_response.ok?
      assert_equal "Child Sponsorship API is up and running".to_json, last_response.body
    end

    def test_no_auth_required
      get api_for('/auth-not-required')
      assert last_response.ok?
      assert_equal last_response_data, { :some_key => 'some_value' }
    end

    def test_auth_required
      get api_for('/auth-required')
      assert_equal 403, last_response.status
    end

    def test_post_login
      create_users
      assert_equal @admin_user.email, 'test@test.com'
      assert_equal @admin_user.password, 'foobar'
      post api_for('/login'), { 'email' => @admin_user.email,
                                'password' => @admin_user.password }.to_json
      token1 = last_response_data[:token]
      refute_nil token1, "Token returned nil"
      assert_equal 200, last_response.status
      # assert_match /^[a-f0-9]{32}$/, token1
      # Test if a second request generates a new token
      post api_for('/login'), { 'email' => @admin_user.email,
                                'password' => @admin_user.password }.to_json
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
      create_users
      post api_for('/login'), { 'email' => @admin_user.email,
                                'password' => @admin_user.password }.to_json
      token = last_response_data[:token]
      refute_nil token
      get api_for("/auth-required?token=#{token}"), { token: token }.to_json
      assert_equal 200, last_response.status
      assert_equal last_response_data, { :some_private_key => 'some_private_value' }
      # GET user
      get api_for("/user?token=#{token}"), { token: token }.to_json
      assert_equal 200, last_response.status
      assert_equal last_response_data, { :email    => 'test@test.com',
                                         :access   => 10 }
      # Test non-admin user access
      post api_for('/login'), { 'email' => @reg_user.email,
                                'password' => @reg_user.password }.to_json
      token = last_response_data[:token]
      # auth not required, non-admin user
      get api_for('/auth-not-required'), { token: token }
      assert_equal 200, last_response.status
      assert_equal last_response_data, { :some_key => 'some_value' }
      # auth-required, non-admin user
      get api_for("/auth-required?token=#{token}"), { token: token }
      assert_equal 403, last_response.status
      # Delete invalidates tokens
      delete api_for('/login'), { token: token }
      get api_for("/auth-required?token=#{token}")
      assert_equal 403, last_response.status
      # Delete with invalid token throws an error
      delete api_for('/tokens'), { token: 'badtoken' }
      assert_equal 404, last_response.status
    end

    def test_all_users
      create_users
      post api_for('/login'), { 'email' => @admin_user.email,
                                'password' => @admin_user.password }.to_json
      token = last_response_data[:token]
      refute_nil token
      get api_for('/users'), { token: token }
      assert last_response_data, { 'email'  => 'test@test.com' }.to_json
    end
  end
end