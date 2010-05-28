module Pushit
  class Config
    include Singleton
    
    attr_accessor :environment, :apple_certificate
    
    def initialize
      @environment = :development
    end
    
    def environment=(environment)
      @environment = environment.to_sym
    end
  end
end
