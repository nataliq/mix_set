module MixSet
  module ApiCommunication

    module SmartId
      URL_PARAM_SUBSTITUTIONS = [
        [ '_[^_]', '__' ],
        [ ' ', '_'  ],
        [ '/', '\\' ],
        [ '.', '^'  ]
      ]
      SINGLE_TYPES = %w[
        all listened recommended liked
      ]
      SMART_TYPES = %w[
        tags keyword artist
      ]
      SORT_TERMS = %w[
        recent hot popular
      ]

      def self.smart_id(type: nil, values: [], sort: nil)
        smart_type = "all"
        if SINGLE_TYPES.include? type
          smart_type = type
        elsif SMART_TYPES.include?(type) and (not values.empty?)
          type_values = values.reduce("") do |result, value| 
            result + "+" + url_param_from_string(value)
          end
          smart_type = type + type_values
        end
        smart_type.concat(":#{sort}") if sort and SORT_TERMS.include? sort

        smart_type
      end

      def self.url_param_from_string(string)
        param = string.clone
        param.strip!
      
        URL_PARAM_SUBSTITUTIONS.each do |decoded, encoded|
          param = param.gsub(decoded, encoded)
        end
        
        Rack::Utils.escape(param)
      end
    end

    class Parser
      attr_accessor :object_class, :nesting

      def initialize(object_class: nil, nesting: [])
        @object_class = "MixSet::ApiCommunication::ApiObjects::#{object_class}" if object_class
        @nesting = nesting
      end

      def parse_json(json)
        return json unless json.class == Hash
        objects = json.get_nested_object nesting
        objects = parse_objects_of_class objects, object_class if object_class and objects

        objects
      end

      private

      def parse_objects_of_class(json, object_class)
        [json].flatten.map { |object_data| Object.const_get(object_class).new object_data }
      end
    end

    module ApiObjects

      class Base8TracksObject
        def initialize(json)
          mapped_properties(json, self.class.mappings).each do |property, value|
            self.send("#{property}=", value)
          end
        end

        def mapped_properties(json, mappings)
         Hash[json.map { |key, value| [(mappings[key] or key), value] }]
        end

        def self.mappings; Hash.new; end

        def method_missing(method, *args) ; end  
      end


      class Mix < Base8TracksObject
        attr_accessor :id, :name, :duration

        def duration=(seconds_string)
          @duration = Time.at(seconds_string.to_i).gmtime.strftime('%R:%S')
        end
      end


      class Track < Base8TracksObject
        attr_accessor :id, :title, :stream_url, :artist

        def self.mappings
          {
            "track_file_stream_url" => "stream_url",
            "name" => "title",
            "performer" => "artist"
          }
        end
        def name
          "#{artist} - #{title}"
        end
      end


      class Tag < Base8TracksObject
        attr_accessor :name, :count

        def self.mappings
          {"cool_taggings_count" => "count"}
        end
      end
    end
  end
end

class Hash
  def get_nested_object(keys)
    array_of_keys = (keys.class == String) ? keys.split("/") : keys
    array_of_keys.reduce(self) do |nested_object, key| 
      next if nested_object.nil?
      nested_object[key.to_s]
    end
  end
end