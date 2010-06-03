require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe "Notification" do
  
  def notification
    @notification ||= Pushit::Notification.new('Alert!', 'foo.aiff', 42)
  end
  
  def test_accessor(name, value)
    notification.send(name, value)
    notification.send(name).should == value
  end
  
  it "should convert the device type to a symbol" do
    notification.device_type = 'iPhone'
    notification.device_type.should == :iPhone
  end
  
  it "should set/get values using custom accessors" do
    test_accessor(:alert, 'Fire!')
    test_accessor(:sound, 'alert.aiff')
    test_accessor(:badge, 42)
    test_accessor(:device_token, '<42234223 42234223 42234223 42234223 42234223 42234223 42234223 42234223>')
    test_accessor(:device_type, :iPhone)
    test_accessor(:custom_data, {'foo' => [1,2,3]})
  end
  
end
