require 'uri'
require 'cgi'
require 'net/http'

module Opentsdb
  class HttpConnection

    MAX_RETRIES = 3

    def initialize(options)
      @options = options.dup
      @host = @options[:host]
      @port = @options[:port] || 4242
      @read_timeout = @options[:read_timeout]
      @open_timeout = @options[:open_timeout]

      at_exit {stop!}
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
          raise response.body
        else
          raise response.body
        end
      end
    end

    def post(url, data)
      headers = {"Content-Type" => "application/json"}
      connect_with_retry do |http|
        request = Net::HTTP::Post.new(url, headers)
        response = http.request(request, data)
        if response.kind_of? Net::HTTPSuccess
          return response
        elsif response.kind_of? Net::HTTPUnauthorized
          raise response.body
        else
          raise response.body
        end
      end
    end

    private

    def stop!
      @stopped = true
    end

    def stopped?
      @stopped
    end

    def connect_with_retry(&block)
      delay,max_delay,retry_count = 0.01,30,0
      begin
        # host,port = @host.split(":")
        http = Net::HTTP.new(@host,@port)
        http.open_timeout = @open_timeout
        http.read_timeout = @read_timeout
        block.call(http)
      rescue Timeout::Error => e
        retry_count += 1
        if (MAX_RETRIES == -1 or retry_count <= MAX_RETRIES) and !stopped?
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
