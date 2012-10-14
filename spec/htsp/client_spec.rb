require 'htsp/client'

describe HTSP::Client do
  subject { described_class.new('192.168.1.10', 9982, 'rspec') }

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
end
