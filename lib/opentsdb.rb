require "socket"
require 'thread'
require 'logger'
require 'json'

module Opentsdb

  def self.logger
    @logger ||= null_logger
  end

  def self.logger=(logger)
    @logger = logger
  end

  private
  def self.null_logger
    devnull = '/dev/null'
    l = Logger.new(devnull)
    l.level = Logger::INFO
    l
  end
end
require 'opentsdb/socket_connection'
require 'opentsdb/http_connection'
require 'opentsdb/metric'
require 'opentsdb/max_queue'
require 'opentsdb/work_thread'
require 'opentsdb/client'
require 'opentsdb/version'
