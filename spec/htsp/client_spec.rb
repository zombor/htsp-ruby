require 'htsp/client'

describe HTSP::Client do
  let(:socket) { TCPSocket.new('192.168.1.10', 9982) }
  subject { described_class.new(socket, 'rspec') }

  context :hello do
    it 'says hello' do
      reply = subject.hello
      reply.should be_a HTSP::Message
      reply.params['challenge'].should_not be_nil
    end

    it 'stores the challenge' do
      subject.hello
      subject.auth.should_not be_nil
    end
  end

  context :authenticate do
    it 'successfully authenticates' do
      subject.hello
      lambda { response = subject.authenticate('jeremybush', 'zombor') }.should_not raise_error
    end

    it 'raises an error if authentication fails' do
      subject.hello
      lambda { subject.authenticate('foo', 'bar') }.should raise_error
    end
  end

  context :authenticated do
    before :each do
      subject.hello
      subject.authenticate('jeremybush', 'zombor')
    end

    it 'gets the system time' do
      response = subject.get_sys_time
      response.params['timezone'].should == 360
    end

    it 'gets getEvents' do
      response = subject.events
      response.params['events'].length.should == 4441
    end

    it 'searches the epg' do
      response = subject.query_events('baseball')
      response.params['events'].length.should == 4
    end
  end

  it 'hashes a digest' do
    challenge = "l6\x06\xcd!\x1ci\xd3\x84\xed\x08\xecX\x1c}\xbex\xa9\xeco\xe7\x06\xe6\xf0\xba%\xbd^\x06?t\xc1"
    password = 'zombor'
    subject.send(:htsp_digest, password, challenge).should == "P~\x7f\x9cb\x94\x0f\xac\x84t\x94\x7f\xd8(K\t\xdbk\xf6\xe5"
  end
end
