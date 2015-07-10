### Opentsdb Ruby Client
---  
 opentsdb-ruby is a Ruby Gem for OpenTSDB that provides core tools when working with an OpenTSDB data store. With opentsdb-ruby, you can search for registered metrics, tag keys and tag values, read from and write to the OpenTSDB, and submit multiple simultaneous queries to an OpenTSDB cluster. support opentsdb 2.1 or higher.  

 ### Build and Installation  

 build it from source and install:  
 ```
git clone https://github.com/dn365/opentsdb-ruby.git
cd opentsdb-ruby
bundle install
gem build opentsdb.gemspec
gem install opentsdb-0.0.1.gem
 ```  
### Usage
Once you have the OpenTSDB cluster set up, we can configure the opentsdb-ruby Gem to talk to the API. The first step would be configuring a TimeSeries client. If no host is specified, the client connects to localhost by default. The client connects to port 4242 by default.  

---  

Connecting to a single host:
```
require 'opentsdb'
client = Opentsdb::Client.new(host:"localhost:4242")
```
Configuring:
* max_queue Type: Integer, Desc: When data is written each write asynchronous mode number
* threads Type: Integer, default: 3, Desc: Set the number of threads to write data
* content_type Type: "socket" & "http", default: "http", Desc: Way links opentsdb  

Writing to OpenTSDB:  
```
require 'opentsdb'

data = {
  metric: "test.cpu.user",
  timestamp: Time.now.to_i,
  value: rand(100),
  tags: {
    host: "node01",
    type: "gauge"
  }
}

# socket connect
client = Opentsdb::Client.new(host:"localhost:4242",max_queue:1000,threads:3,content_type:"socket")

format_data = Opentsdb::Metric.new(data)
client.write_point(format_data)

#http connect
client = Opentsdb::Client.new(host:"localhost:4242",max_queue:200,threads:3)
client.write_point(data)
```

Get Metrics List:
```
client.suggest_metric_list
```

Get All Tags Key List:
```
client.suggest_tags_list
```

Get All Tags vaue List:
```
client.suggest_tags_list("tagv")
```

Get Functions List:
```
client.function_list
```
Get Search Loopup values:
```
metric = "system.cpu.user"
query = "host=node01,type=*"
client.search_loopup(metric,query)
```
Get Time Series Values:
```
data = {
  start: Time.now.utc.to_i - 3600,
  end: Time.now.utc.to_i,
  m: "avg:system.cpu.user{host=node01}"
}
client.query(data)
```
Post Time Series Values:
```
data = {
  start: '1h-ago',
  end: Time.now.utc.to_i,
  queries: [
    {
      aggregator: "avg",
      downsample: "1m-avg",
      metric: "system.cpu.user",
      tags: {
        host: "node01"
      }
    }
  ]
}
client.query(data,"post")
```

### Testing
Run test/client_test.rb
