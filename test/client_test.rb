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
  @client = Opentsdb::Client.new(host:"opentsdb.dntmon.com:80",max_queue:1000,threads:3,content_type:"socket")

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
def get_metrics(name=nil)
  @client.suggest_metric_list(name)
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
    start: "2015/10/01",
    end: "2015/11/01",
    queries: [
      {
        aggregator: "min",
        downsample: "1h-avg-none",
        metric: "system.cpu.idle",
        tags: {
          hostname: nodes.join("|"),
          api_key: "554321df9d6adb0d05be83f90c0f1f38"
        }
      }
    ]
  }
  @client.query(data,"post")
end

def get_query_last
  nodes = ["pqcgh003v01", "pqcgh013v01", "pqcgh024v01", "pqcgh022v02", "pqcgh032v02", "vq15dbgw01", "vq15dbgw02", "vq15dbgw03", "vq15dbgw04", "vq15dbgw05", "vq14stqy09", "vq14stqy03", "vq14stqy04", "vq14stqy01", "vq14stqy02", "vq14stqy05", "vq14stqy06", "vq14stqy07", "vq14stqy08", "vq15zdhcs01", "vd14poccs01", "vd14poccs02", "vd14poccs03", "vd14poccs04", "vd14poccs05", "vd14poccs06", "vd14poccs07", "vd14poccs08", "vd14poccs09", "vd14poccs10", "vd14poccs11", "vd14poccs12", "vq14poccs01", "vq14poccs02", "vq14poccs03", "vq14poccs04", "vq14poccs05", "vq14poccs06", "vq14poccs07", "vq14poccs08", "vq14poccs09", "vq14poccs10", "vq14poccs11", "vq14poccs12", "vq14oapm01", "vq12oapm02", "vq12oapm03", "vq12oapm04", "vd14xxcs01", "vd14xxcs02", "vq14xxcs01", "vq14xxcs02", "vd14rdbcs01", "vd14rdbcs02", "vd14rdbcs03", "vd14rdbcs04", "vq14zjjcs01", "vq14zjjcs02", "vq14zjjcs03", "vq14zjjcs05", "vq14zjjcs06", "vq14zjjcs07", "vq14zjjcs08", "vq14zjjcs09", "vq14zjjcs10", "vd14txfqz01", "vq14txfqz01", "vq16nbu02", "vq16hexd01", "vq16hexd02", "vq12hexd01", "vq16hexd03", "vq16hexd04", "vn12dcos01", "vq12dcos01", "vd15dcos01", "vd15dcos02", "vd15dcos03", "vd15dcos04", "vq16dcos01", "vq16dcos02", "vq16dcos03", "vq16dcos04", "vd15clbyb01", "vq16clbyb01", "vq11yfjt01", "vq11yfjt02", "vq12jhqd01", "vq12gwftp01"]
  timeseries = []
  # timeseries = [
  #   "system.cpu.idle{hostname=#{nodes.join("|")},api_key=554321df9d6adb0d05be83f90c0f1f38}",
  #   "system.mem.phys_pct_usable{hostname=#{nodes.join("|")},api_key=554321df9d6adb0d05be83f90c0f1f38}"
  # ]
  nodes.each{|n|
    # timeseries << "system.cpu.idle{hostname=#{n},api_key=554321df9d6adb0d05be83f90c0f1f38}"
    # timeseries << "system.mem.phys_pct_usable{hostname=#{n},api_key=554321df9d6adb0d05be83f90c0f1f38}"
    timeseries << {
      "metric" => "system.cpu.idle",
      "tags" => {
        "hostname" => n,
        "api_key" => "554321df9d6adb0d05be83f90c0f1f38"
      }
    }
    timeseries << {
      "metric" => "system.mem.phys_pct_usable",
      "tags" => {
        "hostname" => n,
        "api_key" => "554321df9d6adb0d05be83f90c0f1f38"
      }
    }
  }
  # puts timeseries.to_s
  @client.query_last(timeseries,"post")
end

puts get_query_last.to_s
# puts get_metrics("process.user")
# puts post_query.to_json
