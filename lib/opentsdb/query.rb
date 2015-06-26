require 'uri'
require 'cgi'
require 'net/http'
require 'json'

module Opentsdb
  class Query

    DEFAULT_OPTIONS = {
      :host => "127.0.0.1:4242",
      :read_timeout => 300,
      :open_timeout => 5,
      :max_retries => 3
    }

    def initialize(options)
      @options = options.dup
      @host = @options[:host] || DEFAULT_OPTIONS[:host]
      @read_timeout = @options[:read_timeout] || DEFAULT_OPTIONS[:read_timeout]
      @open_timeout = @options[:open_timeout] || DEFAULT_OPTIONS[:open_timeout]

      at_exit {stop!}
    end


    def metric_list(mkey=nil,max=99999)
      options = {type:"metrics",max:max}
      options[:q] = mkey
      url = full_url("/api/suggest",options)
      get(url)
    end

    def tags_list(mkey=nil,type="tagk",max=99999)
      options = {type: type, max: max}
      options[:q] = mkey
      url = full_url("/api/suggest",options)
      get(url)
    end

    def tags_search(skey)
      options = {m: skey}
      url = full_url("/api/search/lookup",options)
      get(url)
    end

    def search(type,options={})
      url = full_url("/api/search/#{type}",options)
      puts url
      get url
    end

    def query(query)
      url = full_url("/api/query", query)
      series = get(url)
      # if block_given?
      #   series.each { |s| yield s['name'], denormalize_series(s) }
      # else
      #   series.reduce({}) do |col, s|
      #     name                  = s['name']
      #     denormalized_series   = denormalize_series s
      #     col[name]             = denormalized_series
      #     col
      #   end
      # end
    end


    private

    def stop!
      @stopped = true
    end

    def stopped?
      @stopped
    end

    def full_url(path, params={})
      query = params.map { |k, v| [CGI.escape(k.to_s), "=", CGI.escape(v.to_s)].join }.join("&")

      URI::Generic.build(:path => path, :query => query).to_s
    end

    def get(url)
      connect_with_retry do |http|
        request = Net::HTTP::Get.new(url)
        response = http.request(request)
        if response.kind_of? Net::HTTPSuccess
          return JSON.parse(response.body)
        elsif response.kind_of? Net::HTTPUnauthorized
          raise response.body.to_s
        else
          raise response.body.to_s
        end
      end
    end

    def connect_with_retry(&block)
      delay,max_delay,retry_count = 0.01,30,0
      begin
        host,port = @host.split(":")
        http = Net::HTTP.new(host,port)
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        block.call(http)
      rescue Timeout::Error => e
        retry_count += 1
        if (DEFAULT_OPTIONS[:max_retries] == -1 or retry_count <= DEFAULT_OPTIONS[:max_retries]) and !stopped?
          sleep delay
          delay = [max_delay, delay * 2].min
          retry
        else
          raise e, "Tried #{retry_count-1} times to reconnect but failed."
        end
      ensure
        http.finish if http.started?
      end
    end

  end
end

# test
client = Opentsdb::Query.new(host:"192.168.59.103:4242")
# client.metric_list()

# list tag keys or tagv
# puts client.tags_list(nil,"tagv")

# puts client.tags_search("system.load.1{host=*}")
puts client.search("tsmeta",{query:"name:system.load.1"})
