module MixSet
  module Interface
    class Console

    	require 'readline'
      require 'mix_set/helpers/colorized_string'
      require 'io/console'
      require 'mix_set'
      require_relative 'commands'
      
      DEFAULT_PROMPT_TEXT = 'MixSet'.freeze
      %w[quit q].each { |method_name| define_method(method_name) { stop_console } }

      def initialize(local: false)
        Readline.completion_append_character = " "
        Readline.completion_proc = proc { |s| MixSetCommand::COMMANDS.grep( /^#{Regexp.escape(s)}/ ) }
        @prompt_text = @default_prompt_text = DEFAULT_PROMPT_TEXT
        @mix_set_player = MixSet.new
        @executor = CommandExecutor.new [self, @mix_set_player]
      end

      def start_console
        @state = `stty -g`.chomp
        trap('INT') { stop_console }
        set_active_user
        
        begin
          while line = Readline.readline(prompt_text, true)
            command = MixSetCommand.new line
            show_response @executor.execution_response command unless command.method.nil?
          end
        rescue Interrupt => e
          stop_console
        end
      end

      def stop_console
        puts "Thanks for using mix_set player! See you soon!"
        system('stty', @state); 
        exit
      end

      def login(params = [])
        while params.compact.count < 2
          case params.compact.count
          when 0
            params[0] = get_user_input "Username: "
          when 1
            params[1] = get_user_input "Password: ", hidden: true
            puts ""
          end
        end

        response = @mix_set_player.login *params
        set_active_user
        response
      end

      private

      def get_user_input(message, hidden: false)
        print message
        hidden ? STDIN.noecho(&:gets).chomp : gets.chomp
      end
      
      def show_response(response)
        if response[:success]
          put_message_with_text response[:success], type: :success
          set_current_prompt_text @mix_set_player.current_state_message
        else
          put_message_with_text response[:error], type: :error
          set_current_prompt_text nil
        end
      end

      def set_active_user
        username = @mix_set_player.current_user
        if username
          show_greeting username
          @default_prompt_text = "#{username}~#{DEFAULT_PROMPT_TEXT}"
          set_current_prompt_text
        end
      end

      def show_greeting(username)
        put_message_with_text "Hello, #{username}!"
      end

      def set_current_prompt_text(text = nil)
        @prompt_text = String.new @default_prompt_text
        @prompt_text.concat " | #{text}" unless text.nil?
        @prompt_text
      end

      def prompt_text
        (@prompt_text + "> ").console_bold.send color_method_for_text_type :prompt
      end

      def color_method_for_text_type(type)
        case type
        when :success
          :console_green
        when :error
          :console_red
        when :help
          :console_blue
        when :prompt
          :console_yellow
        end
      end

      def put_message_with_text(text, type: :success)
        return unless text.is_a? String or text.is_a? Array
        return if text.empty?
        [text].flatten.each { |line| puts line.send(color_method_for_text_type type) }
      end

      def put_help_message_with_text(text)
        puts text.console_blue
      end

    end
  end
end