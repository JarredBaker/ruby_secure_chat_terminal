#!/usr/bin/env ruby

require 'socket'
require 'openssl'

class CommunicationServer
  def initialize(port)
    @ssl_context = OpenSSL::SSL::SSLContext.new
    @ssl_context.cert = OpenSSL::X509::Certificate.new(File.read("server_cert.crt"))
    @ssl_context.key = OpenSSL::PKey::RSA.new(File.read("server_private.key"))
    @ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    # SSL Strong cipher suite.
    @ssl_context.ciphers = 'HIGH:!aNULL:!eNULL'
    # Create SSL server
    @server = TCPServer.new(port)
    # @server = OpenSSL::SSL::SSLServer.new(tcp_server, ssl_context)

    @clients = {}
    @running = true
    puts "Secure chat server started on port #{port}"

    # Start server command listener
    start_command_listener

    run

    trap(:INT) do
      puts "\nShutting down server..."
      shutdown
      exit
    end
  end

  def start_command_listener
    Thread.new do
      loop do
        command = $stdin.gets&.chomp
        case command
        when '/quit'
          puts "Shutting down server..."
          shutdown
          exit
        when '/clients'
          list_clients
        else
          puts "Unknown command. Available commands: /quit, /clients"
        end
      end
    end
  end

  def list_clients
    if @clients.empty?
      puts "No clients connected."
    else
      puts "Connected clients:"
      @clients.each_key do |nickname|
        puts "- #{nickname}"
      end
    end
  end

  def run
    while @running
      begin
        # ssl_client = @server.accept_nonblock

        # Accept a new client connection via TCP
        tcp_client = @server.accept

        # Upgrade to an SSL connection
        ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client, @ssl_context)
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
    nickname = client.gets&.chomp&.to_sym

    if @clients.key?(nickname)
      client.puts "Nickname already in use. Disconnecting."
      client.close
    else
      @clients[nickname] = client
      client.puts "Hi #{nickname}! You can start chatting now."
      broadcast("#{nickname} has joined the chat.", client)
      listen_user_messages(nickname, client)
    end
  end

  def shutdown
    @running = false
    # Notify clients about server shutdown
    broadcast("Server is shutting down.", nil)
    # Close all client connections
    @clients.each do |nickname, client|
      client.puts "Server is shutting down. Disconnecting..."
      client.close
    end
    @clients.clear
    # Close the server socket
    @server.close if @server
    puts "Server has been shut down."
  end

  def listen_user_messages(nickname, client)
    loop do
      msg = client.gets
      break if msg.nil?

      msg = msg.chomp
      if msg == "/quit"
        client.puts "Goodbye!"
        @clients.delete(nickname)
        broadcast("#{nickname} has left the chat.", client)
        client.close
        break
      else
        broadcast("#{nickname}: #{msg}", client)
      end
    end
  rescue => e
    puts "Error: #{e.message}"
    @clients.delete(nickname)
    broadcast("#{nickname} has disconnected due to an error.", client)
    client.close
  end

  def broadcast(message, sender_client)
    @clients.each do |nickname, client|
      client.puts message unless client == sender_client
    end
  end
end

# Start the server
if __FILE__ == $0
  port = ARGV[0] ? ARGV[0].to_i : 3000
  CommunicationServer.new(port)
end
