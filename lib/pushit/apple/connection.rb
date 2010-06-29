module Pushit
  module Apple
    class Connection
      
      PORT          = 2195
      HOST          = 'gateway.push.apple.com'
      SANDBOX_HOST  = 'gateway.sandbox.push.apple.com'
      
      attr_accessor :env
      
      def initialize(certificate, env = :development)
        @certificate = certificate
        @env = env
        open
      end
      
      def open
        raise Pushit::Error, "Certificate must be provided" if @certificate.nil?
        
        ctx = OpenSSL::SSL::SSLContext.new
        ctx.key = OpenSSL::PKey::RSA.new(@certificate)
        ctx.cert = OpenSSL::X509::Certificate.new(@certificate)
        
        @tcp_socket = TCPSocket.new(host, PORT)
        @socket = OpenSSL::SSL::SSLSocket.new(@tcp_socket, ctx)
        @socket.sync = true
        @socket.connect
      end
      
      def close
        @socket.close
        @tcp_socket.close
      end
      
      def deliver(notification)
        message = message_from(notification)
        @socket.write(message)
      end
      
      def host
        (env == :production) ? HOST : SANDBOX_HOST
      end
      
      private
      
      def message_from(notification)
        raise Pushit::InvalidMessage, "Device token must be set" if notification.device_token.nil?
        device_token  = notification.device_token.gsub(/[^0-9a-f]/, '')
        raise Pushit::InvalidMessage, "Device token must be 32 bytes long" if device_token.size != 64 # 64 hex chars = 32 bytes
        payload       = notification_to_json(notification)
        raise Pushit::InvalidMessage, "Payload is bigger than 256 bytes" if payload.size > 256
        
        [0, 32, device_token, payload.size, payload].pack('cnH*nA*')
      end
      
      def notification_to_json(notification)
        aps = {}
        
        # Dictionary-style alert
        if notification.alert.is_a?(Hash)
          alert = {}
          
          # Only include valid keys
          body, action_loc_key, loc_key, loc_args = notification.alert.values_at('body', 'action-loc-key', 'loc-key', 'loc-args')
          
          # Convert to the expected data type
          alert['body']     = body.to_s unless body.nil?        # Must be a string
          alert['loc-key']  = loc_key.to_s unless loc_key.nil?  # Must be a string
                    
          # Must be an array of strings
          if loc_args.is_a?(Array)
            loc_args.map!(&:to_s)
            alert['loc-args'] = loc_args
          end
          
          # Can be null or a string, so check if the hash has the key set
          if notification.alert.has_key?('action-loc-key')
            action_loc_key = action_loc_key.to_s unless action_loc_key.nil?
            alert['action-loc-key'] = action_loc_key
          end
          
          aps['alert'] = alert
        elsif notification.alert != nil
          aps['alert'] = notification.alert.to_s
        end
        
        aps['sound'] = notification.sound.to_s unless notification.sound.nil?
        aps['badge'] = notification.badge.to_i unless notification.badge.nil?
        
        hash = {'aps' => aps}
        hash.merge!(notification.custom_data) if notification.custom_data.is_a?(Hash)
        ActiveSupport::JSON.encode(hash)
      end
      
    end
  end
end
