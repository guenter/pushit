require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Apple Connection" do
  
  def connection
    @connection ||= Pushit::Apple::Connection.new('foo.pem', :development)
  end
  
  def mock_notification
    @mock_notification ||= mock "Notification",
      :alert        => nil,
      :sound        => nil,
      :badge        => nil,
      :device_token => '<42234223 42234223 42234223 42234223 42234223 42234223 42234223 42234223>',
      :device_type  => :iPhone,
      :custom_data  => nil
  end
  
  it "should set the badge and convert the number to an integer" do
    mock_notification.stub(:badge).and_return('3')
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{19.chr}{"aps":{"badge":3}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should set alert" do
    mock_notification.stub(:alert).and_return('Alert!')
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{26.chr}{"aps":{"alert":"Alert!"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should set sound" do
    mock_notification.stub(:sound).and_return('foo.aiff')
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{28.chr}{"aps":{"sound":"foo.aiff"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should allow a payload of up to 256 bytes" do
    mock_notification.stub(:alert).and_return('A' * 236)
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\001\000{"aps":{"alert":"#{'A' * 236}"}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should include custom data" do
    mock_notification.stub(:alert).and_return('Alert!')
    mock_notification.stub(:custom_data).and_return({'hash' => {'foo' => 'bar'}, 'array' => [1,2,3]})
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{63.chr}{"hash":{"foo":"bar"},"aps":{"alert":"Alert!"},"array":[1,2,3]})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should accept a hash for alert and convert the payload to the expected data types" do
    alert = {
      'body'            => 'The text of the message',
      'loc-key'         => :ALERT_MESSAGE,
      'loc-args'        => [1,2],
      'action-loc-key'  => :ACTION_KEY,
      'foo'             => 'Should not be included'
    }
    mock_notification.stub(:alert).and_return(alert)
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{129.chr}) +
        %({"aps":{"alert":{"body":"The text of the message","action-loc-key":"ACTION_KEY","loc-key":"ALERT_MESSAGE","loc-args":["1","2"]}}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should allow nil as value for action-loc-key" do
    alert = {
      'action-loc-key' => nil,
    }
    mock_notification.stub(:alert).and_return(alert)
    
    @ssl_socket_mock.should_receive(:write) do |message|
      message.should == %(\0\0#{32.chr}B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#B#\0#{41.chr}{"aps":{"alert":{"action-loc-key":null}}})
    end
    
    connection.deliver(mock_notification).should be_true
  end
  
  it "should raise an exception if the aps dictionary is empty" do
    lambda {
      connection.deliver(mock_notification)
    }.should raise_error('The "aps" dictionary must have at least one key')
  end
end
