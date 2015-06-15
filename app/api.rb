require 'sinatra/activerecord'
require 'sinatra/cross_origin'
require 'yaml'
Dir["app/lib/**/*.rb"].each{ |f| require File.absolute_path(f)}

module ChildSponsorship
  class Api < Sinatra::Base
    register Sinatra::ActiveRecordExtension
    register Sinatra::CrossOrigin
    attr_reader :current_user

    class << self
      # Namespaces a url resource to a version
      def api_for(resource)
        config = YAML.load File.read('config/child_sponsorship.yml')
        "/api/#{config[:api_version]}#{resource}"
      end
    end

    configure do
      enable :cross_origin
    end

    # CORS stuff for Rails
    options "*" do
      response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "PRIVATE_TOKEN, X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
      200
    end

    before do
      # This seems to get destroyed the minute we reference request.params.  No idea why.
      original_request_body = request.body.read
      @params = request.params.dup
      begin
        @params.merge! JSON.parse(original_request_body)
      rescue JSON::ParserError => e
        # no op, because sometimes JSON parameters are not sent in the body
      end
    end

    set(:auth) do |access_level_required|
      condition {
        @user = User.find_by(token: params['token'])
        ( @user && @user.access >= access_level_required ) or halt(403)
      }
    end

    get api_for('/'), provides: 'json' do
      'Child Sponsorship API is up and running'.to_json
    end

    get api_for('/auth-not-required'), provides: 'json' do
      { 'some-key' => 'some-value' }.to_json
    end

    get api_for('/auth-required'), provides: 'json', :auth => 10 do
      { 'some-private-key' => 'some-private-value' }.to_json
    end

    post api_for('/tokens'), provides: 'json' do
      user = User.find_by(email: params['email'].to_s)
      if user.nil?
        404
      elsif user.authenticate(params['password'])
        token = SecureRandom.hex(16)
        user.token = token
        user.save
        {
          'token' => token,
        }.to_json
      else
        401
      end
    end

    delete api_for('/tokens') do
      user = User.find_by(token: params['token'].to_s)
      if user
        user.token = nil
        user.save
        200
      else
        404
      end
    end

    get api_for('/users'), provides: 'json', :auth => 10 do
      User.all.to_json
    end

    get api_for('/user'), provides: 'json' do
      user = User.find_by(token: params['token'].to_s)
      return 404  if user.nil?
      {
        'email' => user.email,
        'access' => user.access,
      }.to_json
    end

    post api_for '/login' do
      params = json_params
      user = User.authenticate(params[:email], params[:password])
      if user
        user.to_json
      else
        render_no_access
      end
    end

    get api_for('/children') do
      Child.all.to_json
    end

    get api_for('/data-only-users-can-see'), auth: 1 do
      {
        'data' => 'must have at least access level 1 to see this',
      }.to_json
    end

    get api_for('/data-only-admins-can-see'),  auth: 5 do
      {
        'data' => 'must have at least access level 5 to see this',
      }.to_json
    end

    private
      def authenticate
        @current_user = User.find_by_token(params[:private_token])
        render_no_access unless current_user
        current_user
      end

      def json_params
        JSON.parse(request.body.read).symbolize_keys
      end

      def render_no_access
        halt :forbidden, { message: "Acess Denied" }.to_json
      end
  end
end
