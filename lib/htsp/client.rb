require 'socket'
require 'htsp/message'

module HTSP
  class Client
    attr_reader :auth

    def initialize(addr, port, name)
      @socket = TCPSocket.new(addr, port)
      @name = name
    end

    def hello
      args = {
        'htspversion' => 6,
        'clientname' => @name,
      }
      deliver('hello', args)
      response = receive
      @auth = response.params['challenge']
      response
    end

    protected

    def deliver(msg, args)
      args['method'] = msg
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
  end
end
