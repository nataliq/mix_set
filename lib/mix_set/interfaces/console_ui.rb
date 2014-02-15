class MixSetConsole

	require 'readline'
  require 'mix_set'
  require 'mix_set/helpers/colorized_string'

  COMMANDS = %w[
    play pause stop next previous list 
    ].freeze

  def initialize
    Readline.completion_append_character = " "
    Readline.completion_proc = proc { |s| COMMANDS.grep( /^#{Regexp.escape(s)}/ ) }
    @mix_set_player = MixSet.new 
  end

  def start_console
    # Store the state of the terminal
    stty_save = `stty -g`.chomp
    trap('INT') { system('stty', stty_save); exit }
    @prompt = 'mixset'

    begin
      while line = Readline.readline("#{@prompt}> ".console_yellow.console_bold, true)
        put_line line
      end
    rescue Interrupt => e
      system('stty', stty_save) # Restore
      exit
    end
  end

  def put_line(line)
    method, options, params = parse_components(line)
    unless method.nil?
      response = @mix_set_player.public_send method.to_sym, params, options
      case method
      when "play"
        unless response.nil?
          @prompt = response
        else 
          puts "Can't play this mix. Stream not found.".console_red
        end
      when "list"
        response.each { |line| puts line.console_green }
      when "stop"
        @prompt = 'mixset'
      end 
    end
  end

  def parse_components(input)
    command, *rest = input.split(/\s+/)
    options, params =  rest.partition { |string| string =~ /\p{Pd}\S*/ }
    options.each { |option| option.gsub!(/\p{Pd}/, '') }  
    [command, options, params]
  end

end