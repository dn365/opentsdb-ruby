module Opentsdb
  class Metric
    attr_reader :metric, :value, :timestamp, :tags

    def initialize(metric)
      validate(metric,[:metric,:value])
      @name = metric[:metric]
      @value = metric[:value]
      @timestamp = metric[:timestamp] ||  Time.now.to_i
      @tags = metric[:tags] || {}
    end

    def to_s
      result = @tags.map{ |key, value| "#{key}=#{value}" }.join(" ")
      return [@name, @timestamp, @value].join(" ") if result.empty?
      [@name, @timestamp, @value, result].join(" ")
    end

    private
    def validate(config = {}, required_fields)
      required_fields.each do |field|
        next if config.include?(field)
        fail(ArgumentError, "#{field} is required to write into Opentsdb.")
      end
      timestamp = config[:timestamp]
      fail(ArgumentError, 'Timestamp must be numeric') if timestamp && !(timestamp.is_a? Fixnum)
    end
  end
end
