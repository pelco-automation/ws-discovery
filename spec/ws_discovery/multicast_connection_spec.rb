require 'spec_helper'
require 'ws_discovery/multicast_connection'

describe WSDiscovery::MulticastConnection do
  around(:each) do |example|
    EM.run do
      example.run
      EM.stop
    end
  end

  subject { WSDiscovery::MulticastConnection.new(1) }

  describe "#peer_info" do
    before do
      allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:setup_multicast_socket)
      allow(subject).to receive_message_chain(:get_peername, :[], :unpack).and_return(%w(1234 1 2 3 4))
    end

    it "returns an Array with IP and port" do
      expect(subject.send(:peer_info)).to eql ['1.2.3.4', 1234]
    end

    it "returns IP as a String" do
      expect(subject.send(:peer_info).first).to be_a String
    end

    it "returns port as a Fixnum" do
      expect(subject.send(:peer_info).last).to be_a Fixnum
    end
  end

  describe "#setup_multicast_socket" do
    before do
      allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:set_membership)
      allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:switch_multicast_loop)
      allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:set_multicast_ttl)
      allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:set_ttl)
    end

    it "adds 0.0.0.0 and 239.255.255.250 to the membership group" do
      expect(subject).to receive(:set_membership).with(
        IPAddr.new('239.255.255.250').hton + IPAddr.new('0.0.0.0').hton
      )
      subject.send(:setup_multicast_socket)
    end

    it "sets multicast TTL to 1" do
      expect(subject).to receive(:set_multicast_ttl).with(1)
      subject.send(:setup_multicast_socket)
    end

    it "sets TTL to 1" do
      expect(subject).to receive(:set_ttl).with(1)
      subject.send(:setup_multicast_socket)
    end

    context "ENV['RUBY_TESTING_ENV'] != testing" do
      after { ENV['RUBY_TESTING_ENV'] = "testing" }

      it "turns multicast loop off" do
        ENV['RUBY_TESTING_ENV'] = "development"
        expect(subject).to receive(:switch_multicast_loop).with(:off)
        subject.send(:setup_multicast_socket)
      end
    end
  end

  describe "#switch_multicast_loop" do
    before do
      allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:setup_multicast_socket)
    end

    it "passes '\\001' to the socket option call when param == :on" do
      expect(subject).to receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.send(:switch_multicast_loop, :on)
    end

    it "passes '\\001' to the socket option call when param == '\\001'" do
      expect(subject).to receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.send(:switch_multicast_loop,"\001")
    end

    it "passes '\\000' to the socket option call when param == :off" do
      expect(subject).to receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\000"
      )
      subject.send(:switch_multicast_loop,:off)
    end

    it "passes '\\000' to the socket option call when param == '\\000'" do
      expect(subject).to receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\000"
      )
      subject.send(:switch_multicast_loop,"\000")
    end

    it "raises when not :on, :off, '\\000', or '\\001'" do
      expect { subject.send(:switch_multicast_loop, 12312312) }.
        to raise_error(WSDiscovery::Error)
    end
  end
end

