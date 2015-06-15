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
      post api_for('/tokens'), { 'email'      => user.email,
                                 'password'   => user.password }
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
      assert_equal last_response_data, { 'some-key' => 'some-value' }
    end

    def test_auth_required
      get api_for('/auth-required')
      assert_equal 403, last_response.status
    end

    def test_post_tokens
      create_users
      assert_equal @admin_user.email, 'test@test.com'
      post api_for('/tokens'), { 'email'      => @admin_user.email,
                                 'password'   => @admin_user.password }
      assert_equal 200, last_response.status
      token1 = last_response_data['token']
      assert_match /^[a-f0-9]{32}$/, token1
      # Test if a second request generates a new token
      post api_for('/tokens'), { 'email'      => @admin_user.email,
                                 'password'   => @admin_user.password }
      refute_equal token1, last_response_data['token']
      # Invalid credentials do not provide a token
      post api_for('/tokens'), { 'email'      => 'test@test.com',
                                 'password'   => 'badword' }
      assert_equal 401, last_response.status
      # Not found returned if email not found for suer
      post api_for('/tokens'), { 'email'      => 'bad@email',
                                 'password'   => 'badword' }
      assert_equal 404, last_response.status
    end

    def test_admin_access
      create_users
      token = get_token(@admin_user)
      # auth not required, Admin user
      get api_for('/auth-not-required'), { token: token }
      assert_equal 200, last_response.status
      assert_equal last_response_data, { 'some-key' => 'some-value' }
      # auth-required, Admin user
      get api_for("/auth-required?token=#{token}"), { token: token }
      assert_equal 200, last_response.status
      assert_equal last_response_data, { 'some-private-key' => 'some-private-value' }
      # GET user
      get api_for("/user?token=#{token}")
      assert_equal 200, last_response.status
      assert_equal last_response_data, { 'email'    => 'test@test.com',
                                         'access'   => 10 }
      # Test non-admin user access
      token = get_token(@reg_user)
      # auth not required, non-admin user
      get api_for('/auth-not-required'), { token: token }
      assert_equal 200, last_response.status
      assert_equal last_response_data, { 'some-key' => 'some-value' }
      # auth-required, non-admin user
      get api_for("/auth-required?token=#{token}"), { token: token }
      assert_equal 403, last_response.status
      # Delete invalidates tokens
      delete api_for('/tokens'), 'token' => token
      get api_for("/auth-required?token=#{token}")
      assert_equal 403, last_response.status
      # Delete with invalid token throws an error
      delete api_for('/tokens'), { token: 'badtoken' }
      assert_equal 404, last_response.status
    end

    def test_all_users
      create_users
      token = get_token(@admin_user)
      get api_for('/users'), { token: token }
      assert last_response_data, { 'email'  => 'test@test.com' }
    end
  end
end