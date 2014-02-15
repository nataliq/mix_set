class Player

  require 'singleton'
  require 'open4'

  include Singleton

  def initialize
    @mplayer_options = "-slave -quiet"
    @player_path = "mplayer"
  end

  def play(file)
    @file = file
    quit unless @stdin.nil? or @stdin.closed?
    player = "#{@player_path} #{@mplayer_options} #{@file}"
    @pid, @stdin, @stdout, @stderr = Open4.popen4(player)
    starts_playing
  end

  # Quits MPlayer

  def pause; command("pause") ; end

  def stop; command("stop") ; end

  def quit
    command('quit')
    @stdin.close
  end

  def get_time_position
    match = "ANS_TIME_POSITION"
    command("get_time_pos",/#{match}/).gsub("#{match}=","").gsub("'","").to_f
  end

  private

  def starts_playing
    playing = false
    loop  do
      log = @stdout.gets.inspect
      if log =~ /(playback|End of file)/
        playing = log =~ /playback/
        break
      end
    end

    playing
  end

  def command(cmd, match = //)
    @stdin.puts(cmd)
    response = ""
    until response =~ match
      response = @stdout.gets
    end
    response.gsub("\e[A\r\e[K","")
  rescue Errno::EPIPE
    
  end

end