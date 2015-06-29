module Opentsdb
  class SocketConnection

    class ConnectionFailedError < StandardError; end
    class TimeoutException < Exception; end

    attr_reader :host, :port

    def initialize(host, port, socket_timeout_ms)
      @host = host
      @port = port
      @socket_timeout_ms = socket_timeout_ms
      ensure_connected
    end

    def send_request(data)
      ensure_write_or_timeout(data)
    rescue Errno::EPIPE, Errno::ECONNRESET, TimeoutException
      @socket = nil
      raise_connection_failed_error
    end

    def close
      @socket && @socket.close
    end


    private
    def ensure_connected
      if @socket.nil? || @socket.closed?
        begin
          @socket = TCPSocket.new(@host, @port)
        rescue SystemCallError
          raise_connection_failed_error
        end
      end
    end

    def ensure_write_or_timeout(data)
      if IO.select(nil, [@socket], nil, @socket_timeout_ms / 1000.0)
        @socket.write(data)
      else
        raise TimeoutException.new
      end
    end

    def raise_connection_failed_error
      raise ConnectionFailedError, "Failed to connect to #{@host}:#{@port}"
    end


  end
end
