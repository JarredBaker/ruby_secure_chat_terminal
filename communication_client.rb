#!/usr/bin/env ruby

require 'socket'
require 'openssl'
require 'thread'

class CommunicationClient
  def initialize(server_host, server_port)
    # Set up SSL context
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    ssl_context.ca_file = '../server_cert.crt'
    # SSL Strong cipher suite.
    ssl_context.ciphers = 'HIGH:!aNULL:!eNULL'

    # Create SSL socket
    tcp_socket = TCPSocket.new(server_host, server_port)
    @server = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
    @server.sync_close = true
    @server.connect

    @request_queue = Queue.new
    @exit_flag = false
    @logger =
    puts "Connected securely to chat server at #{server_host}:#{server_port}"

    start_listening_thread
    start_sending_thread

    trap(:INT) do
      close_connection
    end

    @listener_thread.join
    @sender_thread.join
  end

  def start_listening_thread
    @listener_thread = Thread.new do
      begin
        loop do
          break if @exit_flag
          msg = @server.gets
          if msg
            puts msg.chomp
          else
            puts "Disconnected from server."
            close_connection
          end
        end
      rescue IOError, EOFError => e
        puts "Listening thread error: #{e.message}"
      ensure
        close_connection
      end
    end
  end

  def start_sending_thread
    @sender_thread = Thread.new do
      begin
        loop do
          break if @exit_flag
          msg = $stdin.gets&.chomp
          break if msg.nil?
          if msg == "/quit"
            @exit_flag = true
            @server.puts msg
            puts "Exiting chat..."
            @server.close unless @server.closed?
            break
          else
            @server.puts msg
          end
        end

        close_connection
      rescue IOError => e
        puts "Sending thread error: #{e.message}"
      ensure
        close_connection
      end
    end
  end

  private

  def close_connection
    @exit_flag = true
    @server.close unless @server.closed?
    puts "Connection closed."
    exit
  end
end

# Connect to the server
if __FILE__ == $0
  host = ARGV[0] || 'localhost'
  port = ARGV[1] ? ARGV[1].to_i : 3000
  CommunicationClient.new(host, port)
end
