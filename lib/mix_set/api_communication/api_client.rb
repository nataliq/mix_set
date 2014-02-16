module ApiCommunication

  module Paging
    def next_page
      @mixes_page = @mixes_page.next
    end

    def previous_page
      @mixes_page = @mixes_page.pred
    end

    def current_page
      @mixes_page
    end

    def page_start
      @mixes_page * @mixes_per_page
    end

    private

    def paging_params
      {page: @mixes_page, per_page: @mixes_per_page}
    end
  end

  module MixesRequests

    include Paging

    def get_mixes
      use_pagination = respond_to? :paging_params
      params = {:include => use_pagination ? "mixes+pagination" : "mixes"}
      params.merge(paging_params) if use_pagination
      parser = Parser.new object_class: "Mix", nesting: "mix_set/mixes"
      objects_for_request "mix_sets/all", params, parser: parser
    end

    def track_for_mix(mix_id, play_next = false)
      track_path = play_next ? "next" : "play"
      parser = Parser.new object_class: "Track", nesting: "set/track"
      objects_for_request("sets/#{@play_token}/#{track_path}", {mix_id: mix_id}, parser: parser).first
    end

    def report_mix(track_id, mix_id)
      objects_for_request "/sets/#{@play_token}/report", {track_id: track_id, mix_id: mix_id}
    end
  end

  module DataStorage

    USER_DATA_FILE_PATH = "supporting_files/user_data.rb"

    def save_user_data(data)
      File.open("user_data.rb", 'w') { |file| file.write Marshal.dump(data) }
    end

    def retrieve_user_data(key = nil)
      if File.exist? USER_DATA_FILE_PATH
        user_data = (Marshal.load File.read(USER_DATA_FILE_PATH) or {})
        user_data[key]
      end
    end

  end

  module Authorization

    include DataStorage

    def authorize(username, password)
      params = {login: username, password: password}
      parser = Parser.new nesting: "user/user_token"
      @user_token = objects_for_request "/sessions", params,  method: :post, parser: parser
      save_user_data({token: @user_token, username: username})
      not @user_token.nil?
    end

    def get_user
      retrieve_user_data :username
    end
  end

  require 'faraday'

  class ApiMiddleware < Faraday::Middleware

    require 'json'

    def call(env)
      @app.call(env).on_complete do |environment|
        env.body = parse env.body
      end
    end

    def parse(body)
      json = JSON.parse body
      json["status"] == "200 OK" ? json : json["errors"]
    end
  end

  class ApiClient

    # BASE_URL = 'http://8tracks.com'
    # API_KEY_HEADER = 'X-Api-Key'
    # API_KEY = '86525d0414507857fbbcf1cdad9606fc8e0efc55'
    # API_VERSION_KEY = "api_version"
    # API_VERSION = 3

    # private_constant :API_KEY

    require 'singleton'
    require_relative '../model/api_objects'

    include Singleton
    include MixesRequests
    include Authorization

    def initialize
      @user_token = retrieve_user_data :token
      options = {:url => "http://8tracks.com", :headers => {'X-Api-Key' => '86525d0414507857fbbcf1cdad9606fc8e0efc55'}, :params => {"api_version" => 3}}
      @connection = Faraday.new(options) do |faraday|
        faraday.request  :url_encoded
        faraday.use ApiMiddleware
        faraday.adapter  Faraday.default_adapter
      end
      @play_token = Parser.new(nesting: "play_token").parse_json json_for_path "/sets/new"
      @mixes_page, @mixes_per_page = 0, 10
    end

    def get_tags
      parser = ApiObjects::Parser.new object_class: "Tag", nesting: "tag_cloud/tags"
      objects_for_request "/tags", parser: parser or []
    end

    private 

    def objects_for_request(path, params = {}, method: :get, parser: nil)
      @connection.public_send(method, "#{path}.json", params).body
      parser.parse_json json unless parser.nil? or []
    end

  end
end