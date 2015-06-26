module Opentsdb
  class Client

    DEFAULT_OPTIONS = {
      :host => "127.0.0.1:4242",
      :max_retries => 3,
      :socket_timeout_ms => 10_000,
      :max_queue => 100,
      :threads => 3,
      :sleep_interval => 3
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

      @connection = build_connection
      @work = WorkThread.new(self,{max_queue:@max_queue,threads:@threads,sleep_interval:@sleep_interval})

    end


    def send_message(metric)
      @connection.send_request(metric)
    end

    def write_point(metric)
      worker.push(metric)
    end




    private
    def build_connection
      host, port = @broker.split(":")
      Connection.new(host,port,@socket_timeout_ms)
    end

    def worker
      return @worker if @worker
      WORKER_MUTEX.synchronize do
        #this return is necessary because the previous mutex holder might have already assigned the @worker
        return @worker if @worker
        @worker = WorkThread.new(self,{max_queue:@max_queue,threads:@threads,sleep_interval:@sleep_interval})
      end
    end

  end
end
