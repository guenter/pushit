module Pushit
  class Notification
    
    def self.better_accessor(*syms)
      syms.flatten.each do |sym|
        class_eval(<<-EOS, __FILE__, __LINE__)
        def #{sym}(*args)
          if args.size == 0
            @#{sym}
          elsif args.size == 1
            @#{sym} = args.first
          else
            raise ArgumentError, "wrong number of arguments (\#{args.size} for 0)"
          end
        end
        
        def #{sym}=(#{sym})
          @#{sym} = #{sym}
        end
        EOS
      end
    end
    
    better_accessor :alert, :sound, :badge, :device_token, :device_type, :custom_data
    
    def initialize(*args)
      @alert, @sound, @badge, @device_token, @device_type, @custom_data = args
    end
    
    def badge=(badge)
      @badge = badge.to_i
    end
  
    def device_type=(device_type)
      @device_type = device_type.to_sym
    end
    
  end
end
