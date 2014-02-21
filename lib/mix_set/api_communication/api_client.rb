module MixSet
  module ApiCommunication
    module DataStorage

      USER_DATA_FILE_PATH = "supporting_files/user_data.rb"

      def save_user_data(data)
        File.open(USER_DATA_FILE_PATH, 'w') { |file| file.write Marshal.dump(data) }
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
        if @user_token
          save_user_data({token: @user_token, username: username})
        end
        @user_token.nil? ? false : username
      end

      def get_user
        retrieve_user_data :username
      end

      def user_with_credentials(username, password)
        authorize(username, password)
      end

      def delete_user_data
        save_user_data({token: nil, username: nil})
      end
    end

    require 'faraday'
    class ApiMiddleware < Faraday::Middleware
      require 'json'

      def call(env)
        @app.call(env).on_complete do |environment|
          environment.body = parse environment.body
        end
      end

      def parse(body)
        json = JSON.parse body
      end
    end

    class ApiClient

      BASE_URL = 'http://8tracks.com'
      API_KEY_HEADER = 'X-Api-Key'
      API_KEY = '86525d0414507857fbbcf1cdad9606fc8e0efc55'
      API_VERSION_KEY = "api_version"
      API_VERSION = 3

      private_constant :API_KEY

      require 'singleton'
      require_relative 'mix_requests'
      require_relative '../model/api_objects'

      include Singleton
      include MixesRequests
      include Authorization

      def initialize
        @user_token = retrieve_user_data :token
        options = {:url => BASE_URL, :headers => {API_KEY_HEADER => API_KEY}, :params => {API_VERSION_KEY => API_VERSION}}
        @connection = Faraday.new(options) do |faraday|
          faraday.request  :url_encoded
          faraday.use ApiMiddleware
          faraday.adapter  Faraday.default_adapter
        end
        @play_token = objects_for_request "/sets/new", parser: Parser.new(nesting: "play_token")
        @mixes_page, @mixes_per_page = 0, 10
      end

      # def get_tags
      #   parser = ApiObjects::Parser.new object_class: "Tag", nesting: "tag_cloud/tags"
      #   objects_for_request "/tags", parser: parser or []
      # end

      private 

      def objects_for_request(path, params = {}, method: :get, parser: nil)
        json = @connection.public_send(method, "#{path}.json", params).body
        objects = (parser.parse_json json unless parser.nil?) or []
      end
    end
  end
end