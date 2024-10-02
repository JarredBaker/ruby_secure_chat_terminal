#!/usr/bin/env ruby

require 'socket'
require 'openssl'
require 'logger'

class CommunicationServer
  def initialize(port)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.cert = OpenSSL::X509::Certificate.new(File.read("../server_cert.crt"))
    @ssl_context.key = OpenSSL::PKey::RSA.new(File.read("../server_private.key"))
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @ssl_context.ciphers = 'HIGH:!aNULL:!eNULL' # SSL Strong cipher suite.
    @server = TCPServer.new(port) # Create TCP server -> Later gets upgraded to SSL

    @clients = {}
    @running = true
    @logger = Logger.new($stdout)
    @logger.info("Secure chat server started on port #{port}")

    start_command_listener

    trap(:INT) do
      signal_shutdown
      exit
    end

    run
  end

  def start_command_listener
    Thread.new do
      loop do
        command = $stdin.gets&.chomp
        terminal_commands = {
          clients: -> { list_clients }
        }
        terminal_commands[command.gsub("/", "").to_sym]&.call
        puts "Unknown command. Available commands: /clients" if terminal_commands[command.gsub("/", "").to_sym].nil?
      end
    end
  end

  def list_clients
    return puts "No clients connected." if @clients.empty?
    puts "Connected clients:"
    @clients.each_key { |nickname| puts "- #{nickname}" }
  end

  def run
    while @running
      begin
        tcp_client = @server.accept
        ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, @ssl_context) # Upgrade to an SSL connection
        ssl_client.accept # Perform the SSL handshake

        Thread.start(ssl_client) do |client|
          handle_client(client)
        end
      rescue IO::WaitReadable, Errno::EINTR
        IO.select([@server])
        retry
      rescue OpenSSL::SSL::SSLError => e
        puts "SSL error: #{e.message}"
      end
    end
  end

  def handle_client(client)
    client.puts "Welcome to the secure chat! Please enter your nickname:"
    nickname = client.gets&.chomp&.to_sym || "Unknown"

    if @clients.key?(nickname)
      client.puts "Nickname already in use. Disconnecting."
      close_socket(client)
    else
      @clients[nickname] = client

      client.puts "Hi #{nickname}! You can start chatting now."
      broadcast("#{nickname} has joined the chat.", client)
      listen_user_messages(nickname, client)
    end
  rescue OpenSSL::SSL::SSLError => e
    puts "SSL error: #{e.message}"
  rescue IOError, EOFError => e
    nickname ||= "Unknown"
    broadcast("#{nickname} has left the chat.", client)
    close_socket(client)
  end

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

  # Broadcast a message to all clients, except the sender
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

  private

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

  # Close the server socket to stop accepting new connections
  def close_server
    close_socket(@server)
  end

  # Close a socket safely, ensuring it is not closed twice
  def close_socket(socket)
    return if socket.closed?
    socket.close rescue IOError
  end

  def log_generic_error(e)
    @logger.error("[GENERIC ERROR]: #{e.message}")
  end
end

# Start the server
if __FILE__ == $0
  port = ARGV[0] ? ARGV[0].to_i : 3000
  CommunicationServer.new(port)
end
