require 'socket'
require 'digest/sha1'
require 'htsp/message'

module HTSP
  class Client
    attr_reader :auth

    def initialize(socket, name)
      @socket = socket
      @name = name
      @seq = 0
    end

    def hello
      args = {
        :htspversion => 6,
        :clientname => @name,
      }
      deliver(:hello, args)
      response = receive
      @auth = response.params['challenge']
      response
    end

    def authenticate(username, password)
      args = {
        :username => username,
        :digest => HTSP::HMF_Bin.new(htsp_digest(password, @auth))
      }
      deliver(:authenticate, args)
      response = receive
      raise 'Authentication failed!' if response.params['noaccess']
    end

    protected

    def deliver(msg, args)
      @seq = @seq + 1
      args[:method] = msg.to_s
      args[:seq] = @seq
      message = Message.new(args)
      @socket.write message.serialize
    end

    def receive
      num_bytes = bin2int(@socket.readpartial(4))
      data = ''
      while data.length < num_bytes
        data = data + @socket.readpartial(num_bytes - data.length)
      end
      Message.new.load_raw(data)
    end

    def bin2int(d)
      (d[0].ord << 24) +
        (d[1].ord << 16) +
        (d[2].ord << 8) +
        d[3].ord
    end

    def htsp_digest(password, challenge)
      Digest::SHA1.digest(password+challenge)
    end
  end
end
