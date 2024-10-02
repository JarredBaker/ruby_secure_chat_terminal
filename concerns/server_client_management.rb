##
# ServerClientManagement provides methods for managing connected clients in a
# chat server. It includes functionalities for adding new clients, listing
# connected clients, and closing client connections during server shutdown.
#
# This module helps to organize the client-related operations that are part of
# the server's responsibilities.
module ServerClientManagement

  ##
  # Adds a new client to the server's list of connected clients.
  #
  # If the given nickname is already in use, the client is disconnected with
  # a message stating that the nickname is taken. Otherwise, the client is added
  # to the list of clients, welcomed to the chat, and their messages are broadcasted
  # to other users.
  #
  # @param [Symbol] nickname The nickname of the client.
  # @param [OpenSSL::SSL::SSLSocket] client The client's SSL socket.
  #
  # @return [void]
  def add_client(nickname, client)
    if @clients.key?(nickname)
      client.puts "Nickname already in use. Disconnecting."
      close_socket(client)
    else
      @clients[nickname] = client
      client.puts "Hi #{nickname}! You can start chatting now."
      broadcast("#{nickname} has joined the chat.", client)
      listen_user_messages(nickname, client)
    end
  end

  ##
  # Lists all connected clients by printing their nicknames.
  #
  # If no clients are connected, it outputs "No clients connected." to the console.
  #
  # @return [void]
  def list_clients
    return puts "No clients connected." if @clients.empty?
    puts "Connected clients:"
    @clients.each_key { |nickname| puts "- #{nickname}" }
  end

  ##
  # Closes all active client connections and clears the list of connected clients.
  #
  # This method is typically called during server shutdown. It sends a message to
  # each client informing them that the server is shutting down and then closes
  # their connection.
  #
  # @return [void]
  def close_clients
    @clients.each do |nickname, client|
      client.puts "Server is shutting down. Goodbye!" rescue IOError
      close_socket(client)
    end
    @clients.clear
  end
end