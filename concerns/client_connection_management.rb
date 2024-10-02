##
# ClientConnectionManagement handles the management of client connections
# within the context of a chat server. It provides functionality to add new
# clients, remove clients, list connected clients, and handle client disconnections.
#
# This module ensures smooth client-server interactions by:
# - Validating and managing client nicknames.
# - Broadcasting messages to all connected clients.
# - Gracefully handling client disconnections.
# - Managing client connections during server shutdown.
#
# Key Methods:
# - `add_client`: Adds a new client to the server and starts listening for messages.
# - `list_clients`: Lists all currently connected clients.
# - `close_clients`: Gracefully closes all client connections, typically during server shutdown.
#
# This module is designed to handle multiple clients in a scalable and thread-safe way.
module ClientConnectionManagement

  ##
  # Starts a new thread to listen for incoming messages from the server.
  # Messages are displayed to the console as they are received.
  #
  # If the connection is closed or an error occurs, the connection is closed and
  # the listening loop is terminated.
  def start_listening_thread
    @listener_thread = Thread.new do
      begin
        loop do
          break if @exit_flag

          if (msg = @server.gets)
            puts msg.chomp
          else
            puts "Disconnected from server."
            close_connection unless @exit_flag
            break
          end
        end
      rescue IOError, EOFError => e
        puts "Listening thread error: #{e.message}"
      ensure
        close_connection unless @exit_flag
      end
    end
  end

  ##
  # Starts a new thread to send user input to the server.
  # Reads user input from the command line and sends it to the server.
  #
  # If the user enters "/quit", the client disconnects and closes the connection.
  def start_sending_thread
    @sender_thread = Thread.new do
      begin
        loop do
          break if @exit_flag

          msg = $stdin.gets&.chomp
          break if msg.nil?

          process_input_message(msg)
        end

        close_connection unless @exit_flag
      rescue IOError => e
        puts "Sending thread error: #{e.message}"
      ensure
        close_connection unless @exit_flag
      end
    end
  end

  ##
  # Closes the SSL connection to the server and exits the program.
  # Ensures the connection is only closed once.
  def close_connection
    @exit_flag = true
    @server.close unless @server.closed?
    puts "Connection closed."
    exit
  end
end
