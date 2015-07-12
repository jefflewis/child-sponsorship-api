require 'sinatra/activerecord'
require 'sinatra/cross_origin'
require 'will_paginate'
require 'will_paginate/active_record'
require 'yaml'
require 'rack/ssl'
require 'aws-sdk'
require 'openssl'

Dir["app/lib/**/*.rb"].each{ |f| require File.absolute_path(f)}

module ChildSponsorship
  class Api < Sinatra::Base
    register Sinatra::ActiveRecordExtension
    register Sinatra::CrossOrigin
    if :environment == :production
      use Rack::SSL
    end

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
      WillPaginate.per_page = 30
      # S3_BUCKET = Aws::S3::Bucket.initialize(ENV['CHILD_SPONSORSHIP_S3_BUCKET'])
    end

    # Cross Origin (CORS)
    options "*" do
      response.headers["Allow"] = "HEAD,GET,PUT,POST,DELETE,OPTIONS"
      response.headers["Access-Control-Allow-Headers"] = "X-Requested-With,
                                                          X-HTTP-Method-Override,
                                                          Content-Type,
                                                          Cache-Control,
                                                          Accept"
      200
    end

    before do
      original_request_body = request.body.read
      @params = request.params.dup
      begin
        @params.merge! JSON.parse(original_request_body, { symbolize_names: true } )
      rescue JSON::ParserError => e
        # Many requests generate an error even though the endpoints work
        # TODO: Figure out why...
        # ¯\_(ツ)_/¯
      end
    end

    set :allow_methods, [:get, :post, :options, :put, :patch, :delete, :head]
    set :expose_headers, ['Content-Type', 'X-Requested-With', 'PRIVATE_TOKEN',
                          'X-HTTP-Method-Override', 'Cache-Control', 'Accept']
    set :protection, :origin_whitelist => ['http://localhost:9000', 'https://child-sponsorship-web.herokuapp.com']

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

    get api_for('/logout') do
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
      User.all.paginate(page: @params[:page]).to_json
    end

    get api_for('/users/:id'), provides: 'json', :auth => 10 do
      user = User.find(@params['id'])
      return 404 if user.nil?
      user.to_json
    end

    post api_for('/users'), provides: 'json', :auth => 10 do
      user = User.new(name:     @params[:name],
                      email:    @params[:email],
                      password: @params[:password])
      return 404 unless user
      user.save
      user.to_json
    end

    put api_for('/users/:id'), provides: 'json' do
      requesting_user = User.find_by(remember_digest: @params['token'])
      user = User.find(@params['id'])
      return 404 unless user
      if requesting_user == user || requesting_user.access >= 10
        # TODO: Refactor this to not be redundant :/
        user.update_attribute(:name, @params['name']) unless @params['name'].nil?
        user.update_attribute(:email, @params['email']) unless @params['email'].nil?
        user.update_attribute(:password, @params['password']) unless @params['password'].nil?
        200
      else
        403
      end
    end

    delete api_for('/users/:id'), provides: 'json', :auth => 10 do
      id = @params['id']
      User.find(id).destroy
      { message: "User: #{id} deleted" }.to_json
    end

    get api_for('/user') do
      user = User.find_by(remember_digest: @params['token'])
      return 404 if user.nil?
      user.to_json
    end

    get api_for('/children'), provides: 'json' do
      Child.includes(:child_photos).all.to_json(:include => :child_photos)
    end

    get api_for('/children/available'), provides: 'json' do
      Child.where(user_id: nil).to_json(:include => :child_photos)
    end

    get api_for('/children/:id'), provides: 'json' do
      child = Child.find(@params['id'])
      return 404 if child.nil?
      child.to_json
    end

    delete api_for('/children/:id'), provides: 'json', :auth => 10 do
      id = @params['id']
      Child.find(id).destroy
      { message: "Child: #{id} deleted" }.to_json
    end

    post api_for('/children'), provides: 'json', :auth => 10 do
      child = Child.new(name:         @params[:name],
                        description:  @params[:description],
                        gender:       @params[:gender],
                        birthdate:    @params[:birthdate],
                        user_id:      @params[:user_id])
      return 404 unless child
      child.save
      child.to_json
    end

    put api_for('/children/:id'), provides: 'json', :auth => 10 do
      child = Child.find(@params['id'])
      return 404 unless child
      # TODO: Refactor this to not be redundant :/
      child.update_attribute(:name, @params['name']) unless @params['name'].nil?
      child.update_attribute(:description, @params['description']) unless @params['description'].nil?
      child.update_attribute(:gender, @params['gender']) unless @params['gender'].nil?
      child.update_attribute(:birthdate, @params['birthdate']) unless @params['birthdate'].nil?
      child.update_attribute(:user_id, @params['user_id']) unless @params['user_id'].nil?
      200
    end

    post api_for('/children/:id/photos/new'), provides: 'json', :auth => 10 do
      child = Child.find(@params['id'])
      return 404 unless child
      photo = ChildPhoto.new(url: @params[:url], caption:  @params[:caption], child_id: child.id)
      photo.save
      200
    end

    # Endoing for returning a pre-signed form for uploading files to S3
    get api_for('/signed_url'), provides: 'json', :auth => 10 do
      {
          policy:                   s3_upload_policy_document,
          signature:                s3_upload_signature,
          access_id:                ENV['AWS_ACCESS_KEY_ID'],
          success_action_redirect:  "/",
          url:                      "https://#{ENV['CHILD_SPONSORSHIP_S3_BUCKET']}.s3.amazonaws.com",
          acl:                      'public-read'
      }.to_json
    end

    get api_for('/data-only-users-can-see'), auth: 1 do
      { 'data' => 'must have at least access level 1 to see this' }.to_json
    end

    get api_for('/data-only-admins-can-see'),  auth: 5 do
      { 'data' => 'must have at least access level 5 to see this' }.to_json
    end

    private
      def render_no_access
        halt 403, { message: "Acess Denied" }.to_json
      end

      # generate the policy document that amazon is expecting.
      def s3_upload_policy_document
        Base64.encode64(
          {
            "expiration": 30.minutes.from_now.utc.strftime('%Y-%m-%dT%H:%M:%S.000Z'),
            "conditions": [
              {"bucket": ENV['CHILD_SPONSORSHIP_S3_BUCKET'] },
              ["starts-with", "$key", ""],
              {"acl": "public-read"},
              {"success_action_status": "201"},
              ["starts-with", "$Content-Type", ""],
              ["starts-with", "$filename", ""],
              ["content-length-range", 0, 524288000]
            ]
          }.to_json
        ).gsub(/\n|\r/, '')
      end

      # sign our request by Base64 encoding the policy document.
      def s3_upload_signature
        Base64.encode64(
            OpenSSL::HMAC.digest(
                OpenSSL::Digest.new('sha1'),
                ENV['AWS_SECRET_ACCESS_KEY'],
                s3_upload_policy_document
            )
        ).gsub(/\n/, '')
      end
  end


end
