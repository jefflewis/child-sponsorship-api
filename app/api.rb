require 'sinatra/activerecord'
require 'sinatra/cross_origin'
require "sinatra/jsonp"
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

    # Cross Origin (CORS)
    options "*" do
      response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "PRIVATE_TOKEN, X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"
      200
    end

    before do
      # This seems to get destroyed the minute we reference request.params.  No idea why.
      original_request_body = request.body.read
      # @request_payload = request.params.dup
      @params = request.params.dup
      begin
        @params.merge! JSON.parse(original_request_body, { symbolize_names: true } )
        # @requst_payload = JSON.parse(original_request_body)
        # @request_payload = JSON.parse request.body.read, { symbolize_names: true }
      rescue JSON::ParserError => e
        # no op, because sometimes JSON parameters are not sent in the body
      end
    end

    set(:auth) do |access_level_required|
      condition {
        token = @params[:token].nil? ? @params['token'] : @params[:token]
        @user = User.find_by(remember_digest: token)
        ( @user && @user.access >= access_level_required ) or render_no_access
      }
    end

    get api_for('/') do
      'Child Sponsorship API is up and running'.to_json
    end

    get api_for('/auth-not-required') do
      { 'some_key' => 'some_value' }.to_json
    end

    get api_for('/auth-required'), :auth => 5 do
      { 'some_private_key' => 'some_private_value' }.to_json
    end

    post api_for('/login'), provides: 'json' do
      # params = @request_payload[:user]
      user = User.find_by(email: @params[:email].to_s)
      if user.nil?
        404
      elsif user.authenticate(@params[:password].to_s)
        user.remember
        { token: user.remember_digest }.to_json
      else
        401
      end
    end

    delete api_for('/login') do
      user = User.find_by(remember_digest: @params['token'])
      if user
        user.forget
        200
      else
        404
      end
    end

    post api_for('/signup'), provides: 'json' do
      user = User.new(email: @params[:email], password: @params[:password])
      if user
        # user.send_activation_email
        user.remember
        { token: user.remember_digest }.to_json
      else
        404
      end
    end

    get api_for('/users'), provides: 'json', :auth => 10 do
      User.all.to_json
    end

    get api_for('/users/:id'), provides: 'json', :auth => 10 do
      user = User.find(@params['id'])
      return 404 if user.nil?
      user.to_json
    end



    get api_for('/user') do
      user = User.find_by(remember_digest: @params['token'])
      return 404 if user.nil?
      user.to_json
    end

    get api_for('/children'), provides: 'json' do
      Child.all.to_json
    end

    get api_for('/children/:id'), provides: 'json' do
      child = Child.find(@params['id'])
      return 404 if child.nil?
      child.to_json
    end

    post api_for('/children'), provides: 'json', :auth => 10 do
      child = Child.new(name:         @params[:name],
                        description:  @params[:description],
                        user_id:      @params[:user_id])
      return 404 unless child
      child.save
      child.to_json
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

      def render_no_access
        halt 403, { message: "Acess Denied" }.to_json
      end

      # def user_params
      #   @params.require(:user).permit(:name, :email, :password)
      # end
  end


end
