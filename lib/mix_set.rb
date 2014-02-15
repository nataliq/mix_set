class MixSet
  
  require_relative 'mix_set/api_communication/api_client'
  require_relative 'mix_set/players/mplayer'

  def initialize(player = Player.instance)
    @mixes = ApiCommunication::ApiClient.instance.get_mixes
    @player = player
  end
  
  def list(*options)
    @mixes.map.with_index { |mix, index| "#{index.succ}. #{mix.name} - #{mix.duration}" }
  end

  def play(params = [], options = [])
    @current_mix = @mixes[params.first.to_i.pred] unless params.first.nil?
    @current_mix ||= @mixes[Random.rand(@mixes.count)]
    
    @current_track = ApiCommunication::ApiClient.instance.track_for_mix @current_mix.id, play_next: (options.include? "next")
    message = nil
    if @current_track and @player.play(@current_track.stream_url)
      track_playing
      message = "Mix: #{@current_mix.name} / Track: #{@current_track.name}"
    end 

    message
    
  end

  def play_next
  end

  def stop(params = [], options = [])
    @player.quit
  end

  def pause(params = [], options = [])
    @player.pause
  end

  def next(params = [], options = [])
    play params, options << "next"
  end

  def previous(params = [], options = [])
    
  end

  def method_missing(method, *args)
    "Ooops.. No such method :)"
  end

  private

  def track_playing
    # @tracking_thread.stop unless @tracking_thread.nil? or @tracking_thread.stop?
    tracking_thread = Thread.new do
      loop do
        if @player.get_time_position >= 30.0
          report_current_song
          break
        else
          sleep 1
        end
      end
    end
  end

  def report_current_song
    ApiCommunication::ApiClient.instance.report_mix @current_mix.id, @current_track.id
    puts "Reported 30 seconds played from track: #{@current_track.name}"
  end
  
end