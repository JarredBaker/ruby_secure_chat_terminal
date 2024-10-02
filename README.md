# ruby_secure_chat_terminal

**Ruby secure chat terminal**: is a thread safe, multi client terminal chat server encrypted through SSL sockets. 

# How to run: 
### openssl key generation and storage. 

##### Generate a private key
```
openssl genrsa -out server_private.key 2048
```

##### Create a certificate signing request (CSR)
```
openssl req -new -key server_private.key -out server_cert.csr
```

##### Generate a self-signed certificate
```
openssl x509 -req -days 365 -in server_cert.csr -signkey server_private.key -out server_cert.crt
```

**Place the files generated 1 directory above the project**

### Start the communication server. 
1. Open a terminal and run:
```ruby
ruby communication_server.rb
```

### Start a client: 

Repeat this step at least twice in a new terminal every time. 

1. Open a terminal and run:
```ruby
ruby communication_client.rb
```

# Improvements: 

TODO
