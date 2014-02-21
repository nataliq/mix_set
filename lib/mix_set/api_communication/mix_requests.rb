module MixSet
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

      #lazy loading
      def mixes_parser
        unless @mixes_parser
          @mixes_parser = Parser.new object_class: "Mix", nesting: "mix_set/mixes"
        end
        @mixes_parser
      end

      def get_mixes(type = nil, values = [], sortings = [])
        use_pagination = respond_to? :paging_params
        params = {:include => use_pagination ? "mixes+pagination" : "mixes"}
        params.merge(paging_params) if use_pagination
        smart_id  = SmartId.smart_id type: type, values: values, sort: sortings.first
        objects_for_request "mix_sets/#{smart_id}", params, parser: mixes_parser
      end

      def track_for_mix(mix_id, play_next = false)
        track_path = play_next ? "next" : "play"
        parser = Parser.new object_class: "Track", nesting: "set/track"
        objects_for_request("sets/#{@play_token}/#{track_path}", {mix_id: mix_id}, parser: parser).first
      end

      def report_mix(track_id, mix_id)
        parser = Parser.new nesting: "errors"
        params = {track_id: track_id, mix_id: mix_id}
        errors = objects_for_request "/sets/#{@play_token}/report", params, parser: parser
        errors.nil? or errors.empty?
      end

      def set_liked_mix(mix_id, liked = true)
        parser = Parser.new nesting: "errors"
        objects_for_request "/mixes/#{mix_id}/#{liked ? "like" : "unlike"}"
      end

      def liked_mixes
        objects_for_request "/mix_sets/liked", {:include => "mixes"}, parser: mixes_parser
      end

      def set_favorited_track(track_id, favourited = true)
        parser = Parser.new nesting: "errors"
        objects_for_request "/tracks/#{track_id}/#{favourited ? "fav" : "unfav"}"
      end

      def favorited_tracks(username)
        parser = Parser.new object_class: "Track", nesting: "tracks"
        objects_for_request "/users/#{username}/favorite_tracks", parser: parser
      end

      def listened_mixes
        objects_for_request "/mix_sets/listened", {:include => "mixes"}, parser: mixes_parser
      end
    end
  end
end