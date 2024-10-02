##
# CommandListener provides functionality to listen for and execute terminal commands
# for managing the server, such as listing connected clients. This module runs a
# command listener in a separate thread and executes corresponding actions based
# on the user's input.
#
# Available Commands:
# - `/clients`: Lists all connected clients.
#
# When an unrecognized command is entered, the user is informed of available commands.
module CommandListener

  ##
  # Starts a new thread to listen for terminal commands. This method reads commands
  # from standard input, processes them, and executes corresponding actions. Supported
  # commands are defined in the `terminal_commands` hash.
  #
  # The command listener runs in an infinite loop and continues to listen for commands
  # until the program is stopped.
  #
  # Supported Commands:
  # - `/clients`: Calls the `list_clients` method to list all connected clients.
  #
  # When an unknown command is entered, the `unknown_command` method is called.
  #
  # @return [Thread] The thread running the command listener.
  def start_command_listener
    Thread.new do
      loop do
        command = $stdin.gets&.chomp
        terminal_commands = {
          clients: -> { list_clients }
        }
        terminal_commands[command.gsub("/", "").to_sym]&.call || unknown_command
      end
    end
  end

  ##
  # Outputs a message informing the user that the entered command is unknown.
  # Lists available commands that can be used with the server.
  #
  # Called when the user enters a command that is not recognized in the
  # `terminal_commands` hash.
  #
  # @return [void]
  def unknown_command
    puts "Unknown command. Available commands: /clients"
  end
end