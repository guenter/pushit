require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Pushit" do
  
  before(:all) do
    Pushit.config.apple_certificate = File.read(File.dirname(__FILE__) + '/fixtures/apple_cert.pem')
  end
  
  it "should raise an exception for unsupported devices" do
    lambda {
      Pushit.deliver { |n| n.device_type :fooPhone }
    }.should raise_error("fooPhone is not supported")
  end
  
  it "should raise an exception if device token is invalid or not given" do
    lambda {
      Pushit.deliver { |n| n.device_type :iPhone }
    }.should raise_error("Device token must be set")
    
    lambda {
      Pushit.deliver { |n|
        n.device_type :iPhone
        n.device_token 'abcd'
      }
    }.should raise_error("Device token must be 32 bytes long")
  end
  
  it "should raise an exception if payload is too big" do
    lambda {
      Pushit.deliver { |n|
        n.alert 'A' * 237
        n.device_type :iPhone
        n.device_token '<42234223 42234223 42234223 42234223 42234223 42234223 42234223 42234223>'
      }
    }.should raise_error("Payload is bigger than 256 bytes")
  end
  
  it "should call deliver on the connection" do
    mock_connection = mock "Connection"
    mock_connection.should_receive(:deliver)
    Pushit.should_receive(:connection_for).and_return(mock_connection)
    Pushit.deliver {}
  end
  
end
