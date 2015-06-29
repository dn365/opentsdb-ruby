module Opentsdb
  class Client

    DEFAULT_OPTIONS = {
      :host => "127.0.0.1:4242",
      :max_retries => 3,
      :socket_timeout_ms => 10_000,
      :max_queue => 100,
      :threads => 3,
      :sleep_interval => 3,
      :read_timeout => 300,
      :open_timeout => 5,
      :content_type => "http" #http or socket
    }

    WORKER_MUTEX = Mutex.new

    attr_reader :socket_timeout_ms, :max_retries
    attr_accessor :worker

    def initialize(options = {})
      options = options.dup

      @broker    = options[:host] || DEFAULT_OPTIONS[:host]
      @socket_timeout_ms = options[:socket_timeout_ms] || DEFAULT_OPTIONS[:socket_timeout_ms]
      @max_send_retries = options[:max_send_retries] || DEFAULT_OPTIONS[:max_send_retries]
      @max_queue = options[:max_queue] || DEFAULT_OPTIONS[:max_queue]
      @threads = options[:threads] || DEFAULT_OPTIONS[:threads]
      @sleep_interval = options[:sleep_interval] || DEFAULT_OPTIONS[:sleep_interval]
      @read_timeout = options[:read_timeout] || DEFAULT_OPTIONS[:read_timeout]
      @open_timeout = options[:read_timeout] || DEFAULT_OPTIONS[:read_timeout]
      @content_type = options[:content_type] || DEFAULT_OPTIONS[:content_type]

      @s_connection = socket_build_connection
      @http_connection = http_build_connection

      @work = WorkThread.new(self,{max_queue:@max_queue,threads:@threads,sleep_interval:@sleep_interval,content_type:@content_type})
    end


    def send_message(metric)
      @s_connection.send_request(metric)
    end

    def write_point(metric)
      worker.push(metric)
    end

    def put_message(metric)
      url = @http_connection.full_url("/api/put")
      data = JSON.generate(metric)
      @http_connection.post(url,data)
    end

    def put_write_point(metric)
      worker.push(metric)
    end

    private
    def socket_build_connection
      host, port = @broker.split(":")
      SocketConnection.new(host,port,@socket_timeout_ms)
    end

    def http_build_connection
      host, port = @broker.split(":")
      HttpConnection.new(host:host, port:port, read_timeout:@read_timeout,open_timeout:@open_timeout)
    end

    def worker
      return @worker if @worker
      WORKER_MUTEX.synchronize do
        #this return is necessary because the previous mutex holder might have already assigned the @worker
        return @worker if @worker
        @worker = WorkThread.new(self,{max_queue:@max_queue,threads:@threads,sleep_interval:@sleep_interval,content_type:@content_type})
      end
    end

  end
end
