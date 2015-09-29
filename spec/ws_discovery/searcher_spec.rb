require 'spec_helper'
require 'ws_discovery/searcher'

describe WSDiscovery::Searcher do
  let(:default_probe) do
    "<s:Envelope xmlns:a=\"http://schemas.xmlsoap.org/ws/2004/08/addressing\" " +
      "xmlns:d=\"http://schemas.xmlsoap.org/ws/2005/04/discovery\" xmlns:s=\"h" +
      "ttp://www.w3.org/2003/05/soap-envelope\"><s:Header><a:Action>http://sch" +
      "emas.xmlsoap.org/ws/2005/04/discovery/Probe</a:Action><a:MessageID>uuid" +
      ":a-uuid</a:MessageID><a:To>urn:schemas-xmlsoap-org:ws:2005:04:discovery" +
      "</a:To></s:Header><s:Body><d:Probe><d:Types/><d:Scopes/></d:Probe></s:B" +
      "ody></s:Envelope>"
  end

  around(:each) do |example|
    EM.run do
      example.run
      EM.stop
    end
  end

  before do
    allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:setup_multicast_socket)
    allow(UUID).to receive(:generate).and_return('a-uuid')
  end

  subject do
    WSDiscovery::Searcher.new(1)
  end

  describe "#initialize" do
    it "does a #probe" do
      expect_any_instance_of(WSDiscovery::Searcher).to receive(:probe)
      subject
    end
  end

  describe "#receive_data" do
    let(:parsed_response) do
      double 'parsed response'
    end

    it "takes a response and adds it to the list of responses" do
      response = double 'response'
      allow(subject).to receive(:peer_info).and_return(['0.0.0.0', 4567])

      expect(subject).to receive(:parse).with(response).exactly(1).times.
        and_return(parsed_response)
      expect(subject.instance_variable_get(:@discovery_responses)).to receive(:<<).
        with(parsed_response)

      subject.receive_data(response)
    end
  end

  describe "#parse" do
    before do
      allow_any_instance_of(WSDiscovery::MulticastConnection).to receive(:setup_multicast_socket)
    end

    it "turns probe matches into WSDiscovery::Responses" do
      result = subject.parse "<Envelope />"
      expect(result).to be_a WSDiscovery::Response
    end
  end

  describe "#post_init" do
    before { allow_any_instance_of(WSDiscovery::Searcher).to receive(:m_search).and_return("hi") }

    it "sends a probe as a datagram over 239.255.255.250:3702" do
      expect(subject).to receive(:send_datagram).
        with(default_probe, '239.255.255.250', 3702).
        and_return 0
      subject.post_init
    end
  end

  describe "#probe" do
    it "builds the probe string using the given parameters" do
      expect(subject.probe(
        env_namespaces: { "xmlns:dn" => "http://www.onvif.org/ver10/network/wsdl" },
        types: "dn:NetworkVideoTransmitter")).to eql <<-PROBE.strip
<s:Envelope xmlns:a=\"http://schemas.xmlsoap.org/ws/2004/08/addressing\" xmlns:\
d=\"http://schemas.xmlsoap.org/ws/2005/04/discovery\" xmlns:s=\"http://www.w3.o\
rg/2003/05/soap-envelope\" xmlns:dn=\"http://www.onvif.org/ver10/network/wsdl\"\
><s:Header><a:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe</a:A\
ction><a:MessageID>uuid:a-uuid</a:MessageID><a:To>urn:schemas-xmlsoap-org:ws:20\
05:04:discovery</a:To></s:Header><s:Body><d:Probe><d:Types>dn:NetworkVideoTrans\
mitter</d:Types><d:Scopes/></d:Probe></s:Body></s:Envelope>
      PROBE
    end
  end
end

