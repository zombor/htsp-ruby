require 'htsp/message'

describe HTSP::Message do
  subject { described_class.new(
    {:htspversion => 6, :method => 'hello', :clientname => 'HTSP RubyClient'}
  )}

  it 'encodes a message for transmission' do
    subject.serialize.should == "\x00\x00\x00B\x02\x0b\x00\x00\x00\x01htspversion\x06\x03\x06\x00\x00\x00\x05methodhello\x03\n\x00\x00\x00\x0FclientnameHTSP RubyClient"
  end

  it 'decodes a htsp encoded message' do
    described_class.new.load_raw("\x02\x0b\x00\x00\x00\x01htspversion\x06\x03\n\x00\x00\x00\rservernameHTS Tvheadend\x03\r\x00\x00\x00\x10serverversion3.1.769~g4303374\x04\t\x00\x00\x00 challenge\xc4Q\x7f\x02\xa7>\"\x8eh#=\xf1\x8d*\x9d\x96\x00_\xb7\xc1\xb5\x98\x89!U\xd2\x83\xc3-\xf4Z*\x05\x10\x00\x00\x00\x00servercapability"
    ).params.should === described_class.new({'htspversion' => 6, 'servername' => 'HTS Tvheadend', 'serverversion' => '3.1.769~g4303374', 'challenge' => "\xc4Q\x7f\x02\xa7>\"\x8eh#=\xf1\x8d*\x9d\x96\x00_\xb7\xc1\xb5\x98\x89!U\xd2\x83\xc3-\xf4Z*", 'servercapability' => {}}).params
  end

  it 'counts messages in binary correctly' do
    subject.send(:binary_count_message, {'htsp_version' => 6, 'method' => 'hello', 'clientname' => 'HTSP PyClient'}).should == 65
  end
end
