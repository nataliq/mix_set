module MixSet
  class MixSetCommand

    COMMANDS = %w[
      login play pause stop status next previous mixes
      ].freeze

    attr_reader :components, :method

    def initialize(input)
      @components = parsed_components input
      @method = @components.first
    end

    def params; @components[1]; end

    def options; @components.last; end

    def self.error_message_for_command(command)
      case command.method
      when :play
        "Can't play this mix. Stream not found."
      when :login
        "Login failed."
      when :stop, :pause
        ""
      when *COMMANDS
        "Network communication problem."
      else
        "Undefined command. If you need help type <help> command."
      end
    end

    def self.success_message_for_command(command)
      case command.method
      when :login
        ""
      else
        nil
      end
    end

    private

    def parsed_components(input)
      command, *rest = input.split(/\s+/)
      rest.each { |option| option.gsub!(/,/, '') } 
      options, params =  rest.partition { |string| string =~ /\p{Pd}\S*/ }
      options.each { |option| option.gsub!(/\p{Pd}/, '') }  
      [command ? command.to_sym : nil, params, options]
    end
  end

  class CommandExecutor

    def initialize(responder_chain)
      @responder_chain = responder_chain
    end

    def execution_response(command)
      response = {}
      result = self.execute command
      if result
        success_message = MixSetCommand.success_message_for_command command
        response[:success] =  success_message.nil? ? result : success_message
      else
        response[:error] = MixSetCommand.error_message_for_command command
      end

      response
    end

    def execute(command)

      result = nil
      @responder_chain.each do |responder|
        if responder.respond_to? command.method
          exact_arity = responder.method(command.method).parameters.count
          result = responder.public_send command.method, *command.components[1, exact_arity]
          break
        end
      end

      result
    end

  end
end