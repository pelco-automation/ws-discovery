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
      WSDiscovery::MulticastConnection.any_instance.stub(:setup_multicast_socket)
      subject.stub_chain(:get_peername, :[], :unpack).and_return(%w(1234 1 2 3 4))
    end

    it "returns an Array with IP and port" do
      subject.peer_info.should == ['1.2.3.4', 1234]
    end

    it "returns IP as a String" do
      subject.peer_info.first.should be_a String
    end

    it "returns port as a Fixnum" do
      subject.peer_info.last.should be_a Fixnum
    end
  end

  describe "#setup_multicast_socket" do
    before do
      WSDiscovery::MulticastConnection.any_instance.stub(:set_membership)
      WSDiscovery::MulticastConnection.any_instance.stub(:switch_multicast_loop)
      WSDiscovery::MulticastConnection.any_instance.stub(:set_multicast_ttl)
      WSDiscovery::MulticastConnection.any_instance.stub(:set_ttl)
    end

    it "adds 0.0.0.0 and 239.255.255.250 to the membership group" do
      subject.should_receive(:set_membership).with(
        IPAddr.new('239.255.255.250').hton + IPAddr.new('0.0.0.0').hton
      )
      subject.setup_multicast_socket
    end

    it "sets multicast TTL to 1" do
      subject.should_receive(:set_multicast_ttl).with(1)
      subject.setup_multicast_socket
    end

    it "sets TTL to 1" do
      subject.should_receive(:set_ttl).with(1)
      subject.setup_multicast_socket
    end

    context "ENV['RUBY_UPNP_ENV'] != testing" do
      after { ENV['RUBY_UPNP_ENV'] = "testing" }

      it "turns multicast loop off" do
        ENV['RUBY_UPNP_ENV'] = "development"
        subject.should_receive(:switch_multicast_loop).with(:off)
        subject.setup_multicast_socket
      end
    end
  end

  describe "#switch_multicast_loop" do
    before do
      WSDiscovery::MulticastConnection.any_instance.stub(:setup_multicast_socket)
    end

    it "passes '\\001' to the socket option call when param == :on" do
      subject.should_receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.switch_multicast_loop :on
    end

    it "passes '\\001' to the socket option call when param == '\\001'" do
      subject.should_receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\001"
      )
      subject.switch_multicast_loop "\001"
    end

    it "passes '\\000' to the socket option call when param == :off" do
      subject.should_receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\000"
      )
      subject.switch_multicast_loop :off
    end

    it "passes '\\000' to the socket option call when param == '\\000'" do
      subject.should_receive(:set_sock_opt).with(
        0, Socket::IP_MULTICAST_LOOP, "\000"
      )
      subject.switch_multicast_loop "\000"
    end

    it "raises when not :on, :off, '\\000', or '\\001'" do
      expect { subject.switch_multicast_loop 12312312 }.
        to raise_error(WSDiscovery::Error)
    end
  end
end

