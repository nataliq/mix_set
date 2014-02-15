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
      parser = Parser.new object_class: "ApiCommunication::ApiObjects::Mix", nesting: "mix_set/mixes"
      json = json_for_path "mix_sets/all", params
      parser.parse_json json unless parser.nil?
    end

    def track_for_mix(mix_id, play_next = false)
      track_path = play_next ? "next" : "play"
      parser = Parser.new object_class: "ApiCommunication::ApiObjects::Track", nesting: "set/track"
      json = json_for_path "sets/#{@play_token}/#{track_path}", {mix_id: mix_id}
      (parser.parse_json(json) or []).first
    end

    def report_mix(track_id, mix_id)
      json_for_path "/sets/#{@play_token}/report", {track_id: track_id, mix_id: mix_id}
    end
  end

  module DataStorage

    USER_DATA_FILE_PATH = "supporting_files/user_data.rb"

    def save_user_data(data)
      File.open("user_data.rb", 'w') { |file| file.write Marshal.dump(data) }
    end

    def retrieve_user_data(key = nil)
      user_data = (Marshal.load File.read(USER_DATA_FILE_PATH) or {})
      user_data[key]
    end

  end

  module Authorization

    include DataStorage

    def authorize(username, password)
      params = {login: username, password: password}
      parser = Parser.new(nesting: "user/user_token")
      @user_token = objects_for_path path: "/sessions", method: :post, params: params, parser: parser
      save_user_data({:token => @user_token})
    end

  end

  class ApiClient

    # BASE_URL = 'http://8tracks.com'
    # API_KEY_HEADER = 'X-Api-Key'
    # API_KEY = '86525d0414507857fbbcf1cdad9606fc8e0efc55'
    # API_VERSION_KEY = "api_version"
    # API_VERSION = 3

    # private_constant :API_KEY

    require 'faraday'
    require 'json'
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
        faraday.adapter  Faraday.default_adapter
      end
      @play_token = Parser.new(nesting: "play_token").parse_json json_for_path "/sets/new"
      @mixes_page, @mixes_per_page = 0, 10
    end

    def get_tags
      parser = ApiObjects::Parser.new object_class: "ApiCommunication::ApiObjects::Tag", nesting: "tag_cloud/tags"
      parser.parse_json json_for_path "/tags" or []
    end

    private 

    def json_for_path(path, params = {}, method = :get)
      json = JSON.parse @connection.public_send(method, "#{path}.json", params).body
    end

  end
end