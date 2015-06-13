require './test/test_helper'

module ChildSponsorship

  class ApiTest < MiniTest::Test

    include Rack::Test::Methods

    def app
      Api
    end

    # def
    #   @user = User.new name:
    # end

    def test_root
      get api_for '/'
      assert last_response.ok?
      assert_equal "Child Sponsorship API is up and running".to_json, last_response.body
    end
  end

end