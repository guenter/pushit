$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'pushit'
require 'spec'
require 'spec/autorun'

Spec::Runner.configure do |config|
  config.before(:each) do
    @ctx_mock        = mock "SSLContext", :key= => nil, :cert= => nil
    @tcp_socket_mock = mock "TCPSocket", :close => true
    @ssl_socket_mock = mock "SSLSocket", :sync= => true, :connect => true, :close => true
    
    TCPSocket.stub(:new).and_return(@tcp_socket_mock)
    OpenSSL::SSL::SSLSocket.stub(:new).and_return(@ssl_socket_mock)
    OpenSSL::SSL::SSLContext.stub(:new).and_return(@ctx_mock)
    OpenSSL::PKey::RSA.stub(:new)
    OpenSSL::X509::Certificate.stub(:new)
  end
end
