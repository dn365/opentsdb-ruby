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
      :max_size => 100_000,
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

      @work = WorkThread.new(self,{max_queue:@max_queue,threads:@threads,sleep_interval:@sleep_interval,content_type:@content_type,max_size:DEFAULT_OPTIONS[:max_size]})
    end


    def send_message(metric)
      @s_connection.send_request(metric)
    end

    def write_point(metric)
      worker.push(metric)
    end

    def put_message(metric)
      url = full_url("/api/put")
      data = JSON.generate(metric)
      post(url,data)
    end

    def function_list
      get full_url("/api/aggregators")
    end

    def suggest_metric_list(mkey=nil,max=99999)
      options = {type:"metrics",max:max}
      options[:q] = mkey
      url = full_url("/api/suggest",options)
      get(url)
    end

    def suggest_tags_list(type="tagk",mkey=nil,max=99999)
      options = {type: type, max: max}
      options[:q] = mkey
      url = full_url("/api/suggest",options)
      get(url)
    end

    def search_loopup(metric,query_str=nil)
      query = query_str.nil? ? metric : metric + '{'+ query_str +'}'
      options = {m: query}
      url = full_url("/api/search/lookup",options)
      data = get url
      tags = {}
      data["results"].each{ |i|
        i["tags"].each{|k,v|
          tags[k] ? tags[k] << v : tags[k] = [v]
        }
      }
      tags.each{|k,v| tags[k] = v.uniq }
      tags
    end

    def query(data,type="get")
      case type
      when "get"
        url = full_url("/api/query", data)
        series = get(url)
      when "post"
        data = JSON.generate(data)
        series = post("/api/query",data)
        series = JSON.parse(series.body)
      end
      series.map{|i| {"metric"=> i["metric"],"tags"=>i["tags"],"values"=> i["dps"].to_a}}
    end

    def query_last(timeseries,type="get")
      case type
      when "get"
        timeserie = timeseries.map{|i| "timeseries="+i}.join("&")
        url = URI.escape("/api/query/last?#{timeserie}&back_scan=24&resolve=true")
        metric_value = get(url)
        value = metric_value.compact
      when "post"
        data = {
          "resolveNames" => true,
          "backScan" => 24
        }
        data["queries"] = timeseries
        data = JSON.generate(data)
        value = post("/api/query/last",data)
        value = JSON.parse(value.body)
      end

      # value
      # value.sort_by{|i| -i["timestamp"]}[0..value.count/2-1]
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

    def full_url(path,options={})
      @http_connection.full_url(path,options)
    end

    def post(url,data)
      @http_connection.post(url,data)
    end

    def get(url)
      @http_connection.get(url)
    end

    def worker
      return @worker if @worker
      WORKER_MUTEX.synchronize do
        #this return is necessary because the previous mutex holder might have already assigned the @worker
        return @worker if @worker
        @worker = WorkThread.new(self,{max_queue:@max_queue,threads:@threads,sleep_interval:@sleep_interval,content_type:@content_type,max_size:DEFAULT_OPTIONS[:max_size]})
      end
    end

  end
end
