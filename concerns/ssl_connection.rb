##
# SSLConnection provides methods for setting up SSL/TLS-secured connections
# for both clients and servers. It configures SSL contexts and handles the
# establishment of encrypted communication over the network.
#
# This module ensures that all connections between the client and server
# are encrypted, providing a secure communication channel.
module SSLConnection

  ##
  # Sets up the SSL connection from the client to the server.
  #
  # This method creates an SSL context, configures it to use strong ciphers and
  # certificate verification, and then establishes a secure connection to the server
  # using the provided hostname and port number. Once connected, the client can
  # communicate securely with the server.
  #
  # @param [String] server_host The hostname or IP address of the server.
  # @param [Integer] server_port The port number of the server.
  #
  # @example
  #   setup_client_ssl_connection('localhost', 3000)
  #
  # @return [void]
  def setup_client_ssl_connection(server_host, server_port)
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
    ssl_context.ca_file = '../server_cert.crt'
    ssl_context.ciphers = 'HIGH:!aNULL:!eNULL'

    tcp_socket = TCPSocket.new(server_host, server_port)
    @server = OpenSSL::SSL::SSLSocket.new(tcp_socket, ssl_context)
    @server.sync_close = true
    @server.connect

    puts "Connected securely to chat server at #{server_host}:#{server_port}"
  end

  ##
  # Sets up the SSL context for the server.
  #
  # This method creates and configures the SSL context for the server, using the
  # server's private key and certificate for secure communication. It sets the SSL
  # ciphers to use strong encryption and configures the context to not require client
  # certificate verification.
  #
  # The SSL context is then returned, allowing the server to upgrade TCP connections
  # to SSL-secured connections.
  #
  # @example
  #   ssl_context = setup_server_ssl_context
  #
  # @return [OpenSSL::SSL::SSLContext] The configured SSL context for the server.
  def setup_server_ssl_context
    ssl_context = OpenSSL::SSL::SSLContext.new
    ssl_context.cert = OpenSSL::X509::Certificate.new(File.read("../server_cert.crt"))
    ssl_context.key = OpenSSL::PKey::RSA.new(File.read("../server_private.key"))
    ssl_context.verify_mode = OpenSSL::SSL::VERIFY_NONE
    ssl_context.ciphers = 'HIGH:!aNULL:!eNULL' # SSL Strong cipher suite.
    ssl_context
  end
end