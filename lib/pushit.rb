require 'singleton'
require 'openssl'
require 'rubygems'
require 'active_support'
require 'pushit/config'
require 'pushit/notification'
require 'pushit/apple/connection'

module Pushit
  
  class << self
    
    def config
      Pushit::Config.instance
    end
    
    def deliver(&block)
      notification = Pushit::Notification.new
      notification.instance_eval(&block)
      connection_for(notification).deliver(notification)
    end
  
    private
  
    def connections
      @@connections ||= {}
    end
  
    def connection_for(notification)
      if notification.device_type == :iPhone
        connections[:iPhone] ||= Pushit::Apple::Connection.new(config.apple_certificate, config.environment)
      else
        raise "#{notification.device_type} is not supported"
      end
    end
  end
  
  
  class Error < StandardError
  end
  
  class InvalidMessage < Error
  end
  
end
