require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Apple Connection" do
  
  def connection
    @connection ||= Pushit::Apple::Connection.new('foo.pem', :development)
  end
  
  def mock_notification
    @mock_notification ||= mock "Notification",
      :alert        => 'Alert!',
      :sound        => 'foo.aiff',
      :badge        => 3,
      :device_token => '<42234223 42234223 42234223 42234223 42234223 42234223 42234223 42234223>',
      :device_type  => :iPhone,
      :custom_data  => nil
  end
  
  it "should format the message correctly and send it" do
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{55.chr}{"aps":{"badge":3,"sound":"foo.aiff","alert":"Alert!"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should leave alert out if nil" do
    mock_notification.stub(:alert).and_return(nil)
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{38.chr}{"aps":{"badge":3,"sound":"foo.aiff"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should leave sound out if nil" do
    mock_notification.stub(:sound).and_return(nil)
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{36.chr}{"aps":{"badge":3,"alert":"Alert!"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should leave badge out if nil" do
    mock_notification.stub(:badge).and_return(nil)
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{45.chr}{"aps":{"sound":"foo.aiff","alert":"Alert!"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should allow a payload of up to 256 bytes" do
    mock_notification.stub(:alert).and_return('A' * 236)
    mock_notification.stub(:sound).and_return(nil)
    mock_notification.stub(:badge).and_return(nil)
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\001\000{"aps":{"alert":"#{'A' * 236}"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should include custom data" do
    mock_notification.stub(:custom_data).and_return({'hash' => {'foo' => 'bar'}, 'array' => [1,2,3]})
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{92.chr}{"hash":{"foo":"bar"},"aps":{"badge":3,"sound":"foo.aiff","alert":"Alert!"},"array":[1,2,3]})
    end
    
    connection.deliver(mock_notification).should be_true
  end
end
