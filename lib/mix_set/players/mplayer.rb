class MPlayer

  require 'singleton'
  require 'open4'

  include Singleton

  def initialize
    @mplayer_options = "-slave -quiet"
    @player_path = "mplayer"
  end

  def play(file)
    @file = file #{}"/Users/nataliyapatsovska/Music/all_night.mp3" #file
    stop
    player = "#{@player_path} #{@mplayer_options} #{@file}"
    @pid, @stdin, @stdout, @stderr = Open4.popen4(player)
    starts_playing?
  end

  # Quits MPlayer

  def pause; command("pause") ; end

  def stop; command("stop") ; end

  def quit
    command('quit')
    @stdin.close unless @stdin.nil? or @stdin.closed?
  end

  def get_time_position
    match = "ANS_TIME_POSITION"
    time_position = -10.0

    time_position_string = command("get_time_pos",/#{match}/)
    if time_position_string
      time_position = time_position_string.gsub("#{match}=","").gsub("'","").to_f
    end
    time_position
  end

  def playing?
    log = @stdout.gets.inspect
    not log.nil?
  end

  private

  def starts_playing?
    playing = false
    1.upto(50).each do
      log = @stdout.gets.inspect
      if log =~ /(Resolving|End of file|playback)/
        playing = log =~ /(Resolving|playback)/
        break
      end
    end
    not playing.nil?
  end

  def command(cmd, match = //)
    unless @stdin.nil? or @stdin.closed?
      @stdin.puts(cmd)
      response = ""
      until response =~ match
        response = @stdout.gets
      end
      response.gsub("\e[A\r\e[K","")
    end
  rescue Errno::EPIPE

  end

end