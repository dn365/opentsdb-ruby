module Opentsdb
  class WorkThread
    attr_reader :client
    attr_accessor :queue

    def initialize(client,options)
      @options = options.dup
      # @queue = Queue.new
      @queue = MaxQueue.new
      @client = client

      spawn_threads!
      at_exit do
        # log :debug, "Thread exiting, flushing queue."
        check_background_queue until @queue.empty?
      end
    end

    def current_threads
      Thread.list.select {|t| t[:opentsdb] == self.object_id}
    end

    def current_thread_count
      Thread.list.count {|t| t[:opentsdb] == self.object_id}
    end

    def push(metric)
      queue.push(metric)
    end

    def spawn_threads!
      @options[:threads].times do |thread_num|

        Thread.new do
          Thread.current[:opentsdb] = self.object_id
          
          while true
            self.check_background_queue(thread_num)
            sleep rand(@options[:sleep_interval])
          end
        end
      end
    end

    def check_background_queue(thread_num = 0)
      # log :debug, "Checking background queue on thread #{thread_num} (#{self.current_thread_count} active)"
      begin
        data = []
        while data.size < @options[:max_queue] && !@queue.empty?
          p_data = @queue.pop(true) rescue next;
          data.push(p_data)
        end
        return if data.empty?
        begin
          send_message(data)
        rescue => e
          puts "Cannot write data: #{e.inspect}"
        end
      end while @queue.length > @options[:max_queue]
    end

    private
    def send_message(data_array)
      data_str = ''
      data_array.each{|i| data_str << "put #{i}" << "\n"}
      @client.send_message(data_str)
    end

  end
end
