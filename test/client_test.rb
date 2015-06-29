require "opentsdb"


METRIC_DATA = {
  metric: "system.test.cpu.user",
  timestamp: Time.now.to_i,
  value: rand(100),
  tags: {
    host: "node01",
    type: "gauge"
  }
}

# test socket write
def socket_write
  @client = Opentsdb::Client.new(host:"192.168.59.103:4242",max_queue:1000,threads:3,content_type:"socket")

  600.times do
    data = []
    (1..2000).each{ |i|
      METRIC_DATA[:timestamp] += 1
      data << METRIC_DATA
    }
    data.each do |i|
      d = Opentsdb::Metric.new(i).to_s
      # puts d
      @client.write_point(d)
    end
    sleep 1
  end
end

# test http write
def http_write
  @client = opentsdb::Client.new(host:"192.168.59.103:4242",max_queue:1000,threads:3)

  (1000*2000).times do
    METRIC_DATA[:timestamp] += 1
    METRIC_DATA[:value] = rand(100)
    @client.put_write_point(METRIC_DATA)
  end
end
