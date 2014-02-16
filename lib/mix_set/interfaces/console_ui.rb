class MixSetConsole

	require 'readline'
  require 'mix_set'
  require 'mix_set/helpers/colorized_string'
  require 'io/console'

  COMMANDS = %w[
    play pause stop next previous list 
    ].freeze
  DEFAULT_PROMPT_TEXT = 'MixSet'

  def initialize
    Readline.completion_append_character = " "
    Readline.completion_proc = proc { |s| COMMANDS.grep( /^#{Regexp.escape(s)}/ ) }
    @mix_set_player = MixSet.new
  end

  def start_console
    stty_save = `stty -g`.chomp
    trap('INT') { system('stty', stty_save); exit }
    show_greeting
    
    begin
      while line = Readline.readline(prompt_text, true)
        execute_command_from_string line
      end
    rescue Interrupt => e
      system('stty', stty_save); 
      exit
    end
  end

  def stop_console(_ = nil, _ = nil)
    puts "See you soon :)"
    # stty_save = `stty -g`.chomp
    # system('stty', stty_save); 
    exit
  end

  alias_method :exit, :stop_console
  alias_method :quit, :stop_console

  def execute_command_from_string(line)
    method, options, params = parse_components(line)
    return if method.nil?
    responder = respond_to?(method) ? self : @mix_set_player
    response = responder.public_send method, params, options
      case method
      when :login, :list
        put_success_message_with_text response
      when :play
        @current_prompt_text = response
        put_error_message_with_text "Can't play this mix. Stream not found." if response.nil?
      when :stop
        @current_prompt_text = nil
      end 
  end

  def login(params = [], _)
    return "Wrong number of params" if params.count > 2

    while params.compact.count < 2
      case params.compact.count
      when 0
        params[0] = get_user_input "Username: "
      when 1
        params[1] = get_user_input "Password: ", hidden: true
        puts ""
      end
    end

    success = @mix_set_player.login *params
    success ? "Succesfull login" : "Not loged in"
    
  end

  def show_greeting
    username = @mix_set_player.current_user_name
    if username
      puts "Hello #{username}"
      @current_prompt_text = username
    end
  end

  def prompt_text
    text = DEFAULT_PROMPT_TEXT
    text.concat "~#{@current_prompt_text}" unless @current_prompt_text.nil?
    text.concat("> ").console_yellow.console_bold
  end

  def put_error_message_with_text(text)
    puts text.console_red
  end

  def put_success_message_with_text(text)
    [text].flatten.each { |line| puts line.console_green }
  end

  def parse_components(input)
    command, *rest = input.split(/\s+/)
    options, params =  rest.partition { |string| string =~ /\p{Pd}\S*/ }
    options.each { |option| option.gsub!(/\p{Pd}/, '') }  
    [command ? command.to_sym : nil, options, params]
  end

  def get_user_input(message, hidden: false)
    print message
    hidden ? STDIN.noecho(&:gets).chomp : gets.chomp
  end

end