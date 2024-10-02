#!/usr/bin/env ruby

require 'socket'
require 'openssl'
require 'thread'
require_relative 'concerns/client_connection_management'
require_relative 'concerns/ssl_connection'

##
# CommunicationClient is a secure, multi-threaded chat client that connects to a
# SSL-secured chat server. It allows a user to send and receive messages in real-time,
# with encrypted communication over SSL/TLS.
#
# Features:
# - SSL encryption for secure communication with the server.
# - Real-time message receiving and sending.
# - Handles graceful disconnections and user-triggered exits via `/quit` or Ctrl+C.
# - Multi-threaded: uses separate threads for listening to and sending messages.
# - Command-based interface to gracefully quit the chat (e.g., sending `/quit`).
#
# Usage:
#   client = CommunicationClient.new('localhost', 3000)
#
# Components:
# - SSLSetup: Sets up the SSL context and handles secure connection establishment.
# - Input Handling: Processes user input and sends messages to the server.
# - Message Listening: Continuously listens for messages from the server.
# - Graceful Shutdown: Ensures proper disconnection when the user quits or Ctrl+C is pressed.
#
# The client runs until manually disconnected, and it supports both user-triggered exits and automatic disconnections if the server shuts down.
class CommunicationClient
  include ClientConnectionManagement
  include SSLConnection

  ##
  # Initializes the client by establishing an SSL connection and starting threads for
  # sending and receiving messages.
  #
  # @param [String] server_host The hostname or IP address of the server.
  # @param [Integer] server_port The port number of the server.
  def initialize(server_host, server_port)
    @exit_flag = false

    setup_client_ssl_connection(server_host, server_port)
    setup_threads

    trap(:INT) { handle_interrupt }

    # Wait for both threads to finish before exiting
    @listener_thread.join
    @sender_thread.join
  end

  private

  ##
  # Starts the listening and sending threads.
  def setup_threads
    start_listening_thread
    start_sending_thread
  end

  ##
  # Handles the user interrupt (Ctrl+C) by setting the exit flag and closing the connection.
  def handle_interrupt
    @exit_flag = true
    close_connection
  end

  ##
  # Processes the input message from the user. If the user enters "/quit",
  # the client disconnects. Otherwise, the message is sent to the server.
  #
  # @param [String] msg The input message from the user.
  def process_input_message(msg)
    handle_quit_message and return if msg == "/quit"
    @server.puts msg
  end

  ##
  # Handles the "/quit" command from the user by setting the exit flag, sending
  # the quit command to the server, and closing the connection.
  def handle_quit_message
    @exit_flag = true
    @server.puts "/quit"
    puts "Exiting chat..."
    close_connection
  end

end

# Connect to the server
if __FILE__ == $0
  host = ARGV[0] || 'localhost'
  port = ARGV[1] ? ARGV[1].to_i : 3000
  CommunicationClient.new(host, port)
end
