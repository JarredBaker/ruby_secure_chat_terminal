#!/usr/bin/env ruby

require 'socket'
require 'openssl'
require 'logger'
require_relative 'concerns/ssl_connection'
require_relative 'concerns/server_client_management'
require_relative 'concerns/command_listener'
require_relative 'concerns/server_error_log'

##
# CommunicationServer is a multi-threaded, SSL-secured chat server that allows
# multiple clients to connect and communicate with each other in real-time.
# It supports encrypted communication over SSL/TLS and provides functionalities
# to handle user commands, broadcast messages, and manage client connections.
#
# Features:
# - SSL encryption for secure client-server communication.
# - Real-time message broadcasting to all connected clients.
# - Command-line interface for managing the server (e.g., listing clients).
# - Handles graceful client disconnections and server shutdowns.
# - Multi-threaded: each client is managed in a separate thread.
#
# Usage:
#   ruby communication_server.rb [Optional port]
#
# Components:
# - SSLSetup module: Handles SSL context creation for encrypted communication.
# - ClientManagement module: Manages client connections, adding/removing clients, and listing connected clients.
# - CommandListener module: Provides a command interface to interact with the server via the terminal.
# - ErrorLogging module: Handles logging of errors for debugging and monitoring.
#
# The server runs continuously and can be terminated via Ctrl+C, which triggers a graceful shutdown.
class CommunicationServer
  include SSLConnection
  include ServerClientManagement
  include CommandListener
  include ServerErrorLog

  ##
  # Initializes the server, sets up SSL and logging, and starts necessary threads.
  #
  # @param [String] port The port to start the server on.
  def initialize(port)
    @ssl_context = setup_server_ssl_context
    @server = TCPServer.new(port) # Create TCP server
    @clients = {}
    @running = true
    @logger = Logger.new($stdout)
    @logger.info("Secure chat server started on port #{port}")

    start_command_listener

    trap(:INT) { signal_shutdown; exit }

    run
  end

  ##
  # Runs the main loop that accepts client connections and handles SSL upgrades.
  def run
    while @running
      begin
        tcp_client = @server.accept
        ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, @ssl_context)
        ssl_client.accept # Perform the SSL handshake

        Thread.start(ssl_client) { |client| handle_client(client) }
      rescue IO::WaitReadable, Errno::EINTR
        IO.select([@server])
        retry
      rescue OpenSSL::SSL::SSLError => e
        log_generic_error(e)
      end
    end
  end

  ##
  # Handles a new client connection, adding them to the client list.
  #
  # @param [OpenSSL::SSL::SSLSocket] client The client socket.
  def handle_client(client)
    client.puts "Welcome to the secure chat! Please enter your nickname:"
    nickname = client.gets&.chomp&.to_sym || "Unknown"

    add_client(nickname, client)
  rescue OpenSSL::SSL::SSLError => e
    log_generic_error(e)
  rescue IOError, EOFError => e
    log_generic_error(e)
    broadcast("#{nickname} has left the chat.", client)
    close_socket(client)
  end

  ##
  # Broadcast a message to all connected clients except the sender.
  #
  # @param [String] message The message to broadcast.
  # @param [OpenSSL::SSL::SSLSocket] sender_client The client that sent the message.
  def broadcast(message, sender_client)
    @clients.each do |nickname, client|
      next if client == sender_client
      begin
        client.puts message
      rescue IOError, OpenSSL::SSL::SSLError => e
        log_generic_error(e)
        client_error_disconnect(nickname, client)
      end
    end
  end

  ##
  # Listens for messages from a client.
  #
  # @param [String] nickname The client's nickname.
  # @param [OpenSSL::SSL::SSLSocket] client The client socket.
  def listen_user_messages(nickname, client)
    loop do
      if (msg = client.gets&.chomp) == "/quit"
        client_quit(client, nickname)
        break
      else
        break if msg.nil?
        broadcast("#{nickname}: #{msg}", client)
      end
    end
  rescue => e
    log_generic_error(e)
    client_error_disconnect(nickname, client)
  end

  private

  ##
  # Handles the disconnection of a client due to an error.
  #
  # @param [Symbol] nickname The nickname of the client.
  # @param [OpenSSL::SSL::SSLSocket] client The client socket.
  def client_error_disconnect(nickname, client)
    broadcast("#{nickname} has disconnected due to an error.", client)
    @clients.delete(nickname)
    close_socket(client)
  end

  def client_quit(client, nickname)
    client.puts "Goodbye!"
    @clients.delete(nickname)
    broadcast("#{nickname} has left the chat.", client)
    close_socket(client)
  end

  # Signal the shutdown safely from the trap context
  def signal_shutdown
    @running = false
    close_clients
    close_server
  end

  # Close all active clients
  def close_clients
    @clients.each do |nickname, client|
      client.puts "Server is shutting down. Goodbye!" rescue IOError
      close_socket(client)
    end
    @clients.clear
  end

  ##
  # Closes the server socket to stop accepting new connections.
  def close_server
    close_socket(@server)
  end

  ##
  # Closes a socket safely, ensuring it is not closed twice.
  #
  # @param [TCPServer | OpenSSL::SSL::SSLSocket] socket The socket to close.
  def close_socket(socket)
    return if socket.closed?
    socket.close rescue IOError
  end
end

# Start the server
if __FILE__ == $0
  port = ARGV[0] ? ARGV[0].to_i : 3000
  CommunicationServer.new(port)
end
