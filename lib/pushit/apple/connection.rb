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
        %w(alert sound badge).each do |key|
          value = notification.send(key)
          aps[key] = value unless value.nil?
        end
        hash = {'aps' => aps}
        hash.merge!(notification.custom_data) if notification.custom_data.is_a?(Hash)
        hash.to_json
      end
      
    end
  end
end
