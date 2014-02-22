module MixSet
  class MixSetCommand

    require_relative 'messages'
    COMMANDS = %w[
      login logout mixes play pause stop next like likes favorite favorites history
      ].freeze

    attr_reader :components, :method

    def initialize(input)
      @components = parsed_components input
      @method = @components.first
    end

    def params; @components[1]; end

    def options; @components.last; end

    private

    def parsed_components(input)
      command, *rest = input.split(/\s+/)
      options, parameters =  rest.partition { |string| string =~ /\p{Pd}\S*/ }
      parameters.each { |parameter| parameter.gsub!(/\W/, '') } 
      options.each { |option| option.gsub!(/\p{Pd}/, '') }  
      [command ? command.to_sym : nil, parameters, options]
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