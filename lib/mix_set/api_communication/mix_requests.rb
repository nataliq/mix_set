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
        parser = Parser.new nesting: "errors"
        params = {track_id: track_id, mix_id: mix_id}
        errors = objects_for_request("/sets/#{@play_token}/report", params, parser: parser)
        errors.nil? or errors.empty?
      end
    end
  end
end