lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "opentsdb"

METRIC_DATA = {
  metric: "system1.test.cpu.user",
  timestamp: Time.now.to_i,
  value: rand(100),
  tags: {
    host: "node01",
    type: "gauge"
  }
}
@client = Opentsdb::Client.new(host:"opentsdb.dntmon.com:80",max_queue:200,threads:1)
# test socket write
def socket_write
  @client = Opentsdb::Client.new(host:"opentsdb.demo.com:80",max_queue:1000,threads:3,content_type:"socket")

  10.times do
    data = []
    (1..2000).each{ |i|
      METRIC_DATA[:timestamp] += 1
      data << METRIC_DATA
    }
    data.each do |i|
      d = Opentsdb::Metric.new(i).to_s
      @client.write_point(d)
    end
  end
end

# test http write
def http_write
  2000.times do
    METRIC_DATA[:timestamp] += 1
    METRIC_DATA[:value] = rand(100)
    @client.write_point(METRIC_DATA)
  end
end

# test http get suggest metrics
def get_metrics
  @client.suggest_metric_list
end

def get_tags_keys
  @client.suggest_tags_list
end

def get_tags_values
  @client.suggest_tags_list("tagv")
end

def get_functions
  @client.function_list
end

def get_tags_values(metric,query)
  @client.search_loopup(metric,query)
end

def get_query
  data = {
    start: Time.now.utc.to_i - 3600,
    end: Time.now.utc.to_i,
    m: "avg:rate:system.cpu.user{hostname=pc-test}"
  }
  @client.query(data)
end

def post_query
  data = {
    start: '1h-ago',
    end: Time.now.utc.to_i,
    queries: [
      {
        aggregator: "avg",
        downsample: "1m-avg",
        metric: "system.cpu.user",
        tags: {
          hostname: "pc-test"
        }
      }
    ]
  }
  @client.query(data,"post")
end

def get_query_last
  timeseries = [
    "system.load.1{hostname=pc-zjqdlog01}",
    "system.cpu.user{hostname=pc-zjqdlog01}"
  ]
  @client.query_last(timeseries)
end

puts get_query_last.to_s
