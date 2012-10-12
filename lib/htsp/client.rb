require 'socket'

module HTSP
  class Client
    def initialize(addr, port, name)
      @socket = TCPSocket.new(addr, port)
      @name = name
    end

    def hello
      args = {
        'htspversion' => 6,
        'clientname' => @name
      }
      deliver('hello', args)
      receive
    end

    protected

    def deliver(msg, args)
      args['method'] = msg
      puts "Sending: #{serialize(args)}".inspect
      @socket.write serialize(args)
    end

    def serialize(msg)
      return int2bin(binary_count(msg)) + binary_write(msg)
    end

    def deserialize(data)
      msg = {}

      while data.length > 5
        type = data[0].ord
        nlen = data[1].ord
        data_length = bin2int(data[2..5])
        data = data[6..-1]

        #raise 'not enough data' if len < nlen + dlen

        name = data[0..nlen-1]
        data = data[nlen..-1]

        if type == HMF_STR
          item = data[0..data_length-1]
        elsif type == HMF_BIN
          item = hmf_bin(data[0..data_length-1])
        elsif type == HMF_S64
          item = 0
          i = data_length - 1
          while i >= 0
            item = (item << 8) | data[i].ord
            i = i - 1
          end
        elsif [HMF_LIST, HMF_MAP].include? type
          item = deserialize data[0..data_length-1]
        end

        msg[name] = item
        data = data[data_length..-1]
      end

      msg
    end

    def receive
      msg = @socket.gets
      puts "Receiving: #{msg}".inspect
      deserialize msg
    end

    def binary_count(msg)
      ret = 0
      msg.each_pair do |k, v|
        ret = ret + 6
        ret = ret + k.to_s.length + _binary_count(v)
      end
      ret
    end

    def _binary_count(value)
      if value.is_a? String
        value.length
      elsif value.is_a? Integer
        ret = 0
        while value > 0 do
          ret = ret + 1
          value = value >> 8
        end
        ret
      end
    end

    def binary_write(msg)
      ret = ''
      msg.each_pair do |k, v|
        ret = ret + (hmf_type(v)).chr
        ret = ret + (k.length & 0xFF).chr

        l = _binary_count(v)
        ret = ret + int2bin(l)
        ret = ret + k.to_s

        if v.is_a? String
          ret = ret + v
        elsif v.is_a? Integer
          while v > 0 do
            ret = ret + (v & 0xFF).chr
            v = v >> 8
          end
        end
      end

      ret
    end

    def int2bin(i)
      (i >> 24 & 0xFF).chr + (i >> 16 & 0xFF).chr + (i >> 16 & 0xFF).chr + (i & 0xFF).chr
    end

    def bin2int(d)
      (d[0].ord << 24) +
        (d[1].ord << 16) +
        (d[2].ord << 8) +
        d[3].ord
    end

    HMF_MAP  = 1
    HMF_S64  = 2
    HMF_STR  = 3
    HMF_BIN  = 4
    HMF_LIST = 5
    def hmf_type(value)
      if value.is_a? String
        HMF_STR
      elsif value.is_a? Integer
        HMF_S64
      end
    end

    def hmf_bin(str)
      str
    end
  end
end