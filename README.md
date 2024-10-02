# Ruby secure chat terminal [WIP]

## Overview

The **Ruby secure chat terminal** is a multi-threaded, SSL/TLS-encrypted chat system built using Ruby. It consists of a server that supports multiple clients, allowing them to communicate in real time. The communication between the server and clients is encrypted to ensure privacy and security.

### Features:
- **SSL/TLS Encryption**: Secure communication using strong encryption ciphers.
- **Multi-threaded**: Each client is handled in a separate thread, allowing for simultaneous connections and real-time chat.
- **Command Interface**: The server includes a command-line interface for server management, including listing connected clients.
- **Graceful Shutdown**: The server and clients handle shutdowns and disconnections gracefully, ensuring a clean exit.
- **Logging**: Errors and key events are logged for debugging and monitoring purposes.

## Project Structure

The project is organized into modules that handle different responsibilities:

- **Server**: Manages client connections, broadcasts messages, and ensures secure communication.
- **Client**: Allows users to connect to the chat server, send messages, and receive real-time chat updates.
- **Modules**:
  - **CommandListener**: Handles server-side command input from the terminal, such as listing connected clients.
  - **ClientConnectionManagement**: Manages adding, removing, and listing connected clients on the server.
  - **SSLConnection**: Handles setting up SSL/TLS contexts and connections for both the server and clients.
  - **ServerErrorLog**: Provides error logging functionality for the server.

## Components

### Server
The `CommunicationServer` class is the backbone of the chat server. It accepts incoming client connections, upgrades them to SSL, and facilitates real-time communication between connected clients.
  
#### Usage:
```bash
ruby communication_server.rb
```

The server listens on a specified port and allows multiple clients to connect securely. It supports terminal commands such as listing connected clients via `/clients`.

### Client
The `CommunicationClient` class allows a user to connect to the server, send messages, and receive chat updates. The client establishes an SSL connection to ensure encrypted communication.

#### Usage:
```bash
ruby communication_client.rb
```

Clients can send messages, receive real-time updates, and gracefully exit the chat with `/quit` or by pressing Ctrl+C.

## Installation

### Prerequisites:
- Ruby 2.7 or higher
- OpenSSL

### Steps:
1. Clone the repository:
   ```bash
   git clone https://github.com/JarredBaker/ruby_secure_chat_terminal.git
   cd ruby_secure_chat_terminal
   ```
3. Set up certificates:
   - Place your SSL certificates one direcroy above the root of the project:
     - `server_cert.crt`: The server's SSL certificate.
     - `server_private.key`: The server's private key.
   - Ensure the certificates are correctly referenced in the code.

## Running the Application

### Start the Server:
```bash
ruby communication_server.rb 3000
```
This starts the server on port `3000`. The server will wait for clients to connect and will manage SSL-encrypted communication.

### Connect a Client:
Perform this step multiple times to chat with other users. (User per terminal)

```bash
ruby communication_client.rb localhost 3000
```

This command connects the client to the server running on `localhost` at port `3000`.

### Server Commands:
- `/clients`: Lists all currently connected clients in the server terminal.

### Client Commands:
- `/quit`: Disconnects the client from the server and exits the chat.

## SSL Certificates

For testing, you can generate self-signed certificates using OpenSSL:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout server_private.key -out server_cert.crt
```

# Improvements: 

- [ ] **End to end encryption**.
- [ ] **Secure store for certificates**
- [ ] **Self hosted DB for user persistence**
- [ ] **Authentication**
- [ ] **Ngrok or self hosting testing**
- [ ] **Signal to notify friends when you online**
- [ ] **Pending messages**
