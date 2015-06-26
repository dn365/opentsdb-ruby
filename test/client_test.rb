require "opentsdb"

@client = Opentsdb::Client.new(host:"192.168.59.103:4242",max_queue:1000,threads:3)

600.times do
  data = []
  (1..1000).each{ |i|
    data << {
      name: "system.cpu.user",
      timestamp: Time.now.to_i,
      value: rand(100),
      tags: {
        host: "pc-mon#{i}",
        type: "gauge",
        cpu: i
      }
    }
  }
  #   {
  #     name: "system.load.1",
  #     timestamp: Time.now.to_i,
  #     value: rand(100),
  #     tags: {
  #       host: "pc-mon01",
  #       type: "gauge"
  #     }
  #   },
  #   {
  #     name: "system.load.5",
  #     timestamp: Time.now.to_i,
  #     value: rand(100),
  #     tags: {
  #       host: "pc-mon01",
  #       type: "gauge"
  #     }
  #   },
  #   {
  #     name: "system.load.15",
  #     timestamp: Time.now.to_i,
  #     value: rand(100),
  #     tags: {
  #       host: "pc-mon01",
  #       type: "gauge"
  #     }
  #   }
  # ]

  data.each do |i|
    d = Opentsdb::Metric.new(i).to_s
    # puts d
    @client.write_point(d)
  end
  sleep 1
end
