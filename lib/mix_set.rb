module MixSet
  class MixSet
    
    require_relative 'mix_set/api_communication/api_client'
    require_relative 'mix_set/players/mplayer'

    attr_reader :current_mix, :current_track, :current_user
    attr_reader :playing
    alias :playing? :playing

    def initialize(data_source = ApiCommunication::ApiClient.instance, player = MPlayer.instance)
      @data_source = data_source
      @player = player

      @mixes = @data_source.get_mixes
      @current_user = @data_source.get_user
      
      @playing = @paused = false
    end

    def login(username, password)
      @current_user = @data_source.user_with_credentials username, password
    end

    def logout
      @data_source.delete_user_data
      @current_user = nil
    end

    def current_state_message
      if playing?
        "Mix: #{@current_mix.name} | Track: #{current_track.artist} - #{@current_track.title} ♬ ♪ "
      elsif @paused
        "Mix: #{@current_mix.name} | Paused"
      else
        nil
      end
    end

    def mixes(parameters = [], options = [])
      unless parameters.empty? and options.empty?
        key, *values = *parameters
        @mixes = @data_source.get_mixes key, values, options
      end
      
      list_mixes @mixes
    end

    def favorites
      tracks = @data_source.favorited_tracks @current_user
      tracks.map(&:name) if tracks
    end

    def likes
      mixes = @data_source.liked_mixes
      list_mixes mixes
    end

    def listened
      mixes = @data_source.listened_mixes
      list_mixes mixes
    end

    def tracking?
      (not @tracking_thread.nil?) and @tracking_thread.alive? and @tracking_thread.status != "sleep"
    end

    def play(params = [], options = [])
      return pause if @paused and params.empty? and options.empty?
      @current_mix = @mixes[params.first.to_i.pred] if params.first
      @current_mix ||= @mixes[Random.rand(@mixes.count)]
      @current_track = @data_source.track_for_mix @current_mix.id, play_next: (options.include? :next)
      if current_track.nil?
        success = false
      else
        success = @player.play(@current_track.stream_url)
      end
      self.playing = success
    end

    def stop
      self.playing = false
      @player.quit
    end

    def pause
      if playing? ^ @paused
        self.playing = !playing?
        @paused = !@paused
        @player.pause
      end
    end

    def next
      play [], [:next]
    end

    def like 
      @data_source.set_liked_mix @current_mix.id unless @current_mix.nil?
    end

    def favorite
      @data_source.set_favorited_track @current_track.id unless @current_track.nil?
    end

    private 

    def playing=(playing)
      @playing = playing
      @tracking_thread.terminate unless @tracking_thread.nil? or playing
      track_playing if playing
    end

    def list_mixes(mixes)
      mixes.map.with_index { |mix, index| "#{index.succ}. #{mix.name} - #{mix.duration}" } if mixes
    end

    def track_playing
      # @tracking_thread.stop unless @tracking_thread.nil? or @tracking_thread.stop?
      @tracking_thread = Thread.new do
        should_report = @data_source.respond_to? :report_mix
        loop do
          break unless playing?
          if not @player.playing?
            sleep 1
            self.next 
            break
          elsif @player.get_time_position >= 30.0 and should_report
            @data_source.report_mix @current_mix.id, @current_track.id
            should_report = false
          end
          sleep 1
        end
      end
    end


  end
end