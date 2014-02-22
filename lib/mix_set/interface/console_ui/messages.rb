module MixSet
  class MixSetCommand
    def self.help_for_method(method)
      description, usages = "", ["#{method.to_s}"]
      case method
      when :login
        description = "Authorize user with his 8tracks account."
        usages = ["login", "login <username>", "login <username>, <password>"]
      when :logout
        description = "Clear saved user data."
      when :mixes
        description = "Show list of mixes which can be played. You can search by tags, keyword or artist. Also you can list listened, liked or recommended mixes. \nAvailable options: -recent, -hot, -popular"          
        usages = ["mixes", "mixes tags: <tag1>, <tag2>..", "mixes artist: <artist>", "mixes keyword: <keyword_string>", "mixes listened", "mixes liked", "mixes recommended"]
      when :play
        description = "Play mix if there is available stream for it. When used without arguments it selects random mix or last played."
        usages = ["play", "play <mix_number>"]
      when :stop, :pause
        description = "#{method.to_s.capitalize}s played track if any."
      when :next
        description = "Play next track in the mix if it is available."
      when :history
        description = "Show all played mixes by current user"
      when :like, :favorite
        item = method == :like ? "mix" : "track"
        description = "Mark current #{item} as #{method.to_s}d."
      when :likes, :favorites
        description = "Show list of all #{method.to_s}."
      end
      "#Method: {method}\nDescription: #{description}\n\nUsages:\n    #{usages * "\n    "}\n"
    end

    def self.error_message_for_command(command)
      case command.method
      when :play
        "Can't play this mix. Stream not found."
      when :login
        "Login failed."
      when :stop, :pause, :logout, :help
        ""
      when :like, :likes, :favorites, :favorite
        "You have to login first."
      when *COMMANDS
        "Network communication problem."
      else
        "Undefined command. If you need help type <help> command."
      end
    end

    def self.success_message_for_command(command)
      case command.method
      when :login, :help
        ""
      when :like, :favorite
        item = command.method == :like ? "mix" : "track"
        "You successfully #{command.method.to_s}d current #{item}."
      else
        nil
      end
    end
  end
end