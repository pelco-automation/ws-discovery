require 'spec_helper'
require 'ws_discovery/response'

describe WSDiscovery::Response do
  let(:probe_response) do
    <<-PROBE
      <s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope"
        xmlns:a="http://schemas.xmlsoap.org/ws/2004/08/addressing"
        xmlns:d="http://schemas.xmlsoap.org/ws/2005/04/discovery">
        <s:Header>
          <a:To>http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous</a:To>
          <a:Action>http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches</a:Action>
          <a:MessageID>urn:uuid:18523f7e-7a54-d92d-a18d-e7165bec8e7e</a:MessageID>
          <a:RelatesTo>uuid:7dbdede0-0f2b-0130-5861-002564b29b24</a:RelatesTo>
          <d:AppSequence MessageNumber="42" InstanceId="2"/>
        </s:Header>
        <s:Body>
          <d:ProbeMatches>
            <d:ProbeMatch>
              <a:EndpointReference>
                <a:Address>urn:uuid:0b679890-fc54-14ba-d428-f73b3e7c2400</a:Address>
              </a:EndpointReference>
              <d:Types xmlns:dn="http://www.onvif.org/ver10/network/wsdl">dn:NetworkVideoTransmitter</d:Types>
              <d:Scopes>onvif://www.onvif.org/Profile/Streaming onvif://www.onvif.org/hardware/NET5404T onvif://www.onvif.org/type/ptz onvif://www.onvif.org/type/video_encoder onvif://www.onvif.org/location/country/usa onvif://www.onvif.org/name/NET5404T-ABEPZH7</d:Scopes>
              <d:XAddrs>http://10.221.222.74/onvif/device_service</d:XAddrs>
              <d:MetadataVersion>1</d:MetadataVersion>
            </d:ProbeMatch>
          </d:ProbeMatches>
        </s:Body>
      </s:Envelope>
    PROBE
  end

  let(:probe_body_hash) do
    { probe_matches: {
      probe_match: {
        endpoint_reference: {
          address: "urn:uuid:0b679890-fc54-14ba-d428-f73b3e7c2400" },
        types: "dn:NetworkVideoTransmitter",
        scopes: "onvif://www.onvif.org/Profile/Streaming onvif://www.onvif.org/hardware/NET5404T onvif://www.onvif.org/type/ptz onvif://www.onvif.org/type/video_encoder onvif://www.onvif.org/location/country/usa onvif://www.onvif.org/name/NET5404T-ABEPZH7",
        x_addrs: "http://10.221.222.74/onvif/device_service",
        metadata_version: "1" } } }
  end

  let(:probe_header_hash) do
    { to: "http://schemas.xmlsoap.org/ws/2004/08/addressing/role/anonymous",
      action: "http://schemas.xmlsoap.org/ws/2005/04/discovery/ProbeMatches",
      message_id: "urn:uuid:18523f7e-7a54-d92d-a18d-e7165bec8e7e",
      relates_to: "uuid:7dbdede0-0f2b-0130-5861-002564b29b24",
      app_sequence: {
        :@message_number => "42",
        :@instance_id => "2" } }
  end

  let(:probe_full_hash) do
    { envelope: { header: probe_header_hash, body: probe_body_hash,
      :"@xmlns:s" => "http://www.w3.org/2003/05/soap-envelope",
      :"@xmlns:a" => "http://schemas.xmlsoap.org/ws/2004/08/addressing",
      :"@xmlns:d" => "http://schemas.xmlsoap.org/ws/2005/04/discovery" } }
  end
  subject { WSDiscovery::Response.new(probe_response) }

  describe "#[]" do
    it "should return the SOAP response body as a Hash" do
      subject[:probe_matches].should == probe_body_hash[:probe_matches]
    end

    it "should throw an exception when the response body isn't parsable" do
      expect { WSDiscovery::Response.new('').body }.to raise_error WSDiscovery::Error
    end
  end

  describe "#header" do
    it "should return the SOAP response header as a Hash" do
      subject.header[:app_sequence].should == probe_header_hash[:app_sequence]
    end

    it "should throw an exception when the response header isn't parsable" do
      expect { WSDiscovery::Response.new('').header }.to raise_error WSDiscovery::Error
    end
  end

  %w(body to_hash).each do |method|
    describe "##{method}" do
      it "should return the SOAP response body as a Hash" do
        subject.send(method)[:probe_matches].should == probe_body_hash[:probe_matches]
      end
    end
  end

  describe "#hash" do
    it "should return the complete SOAP response XML as a Hash" do
      subject.hash.should == probe_full_hash
    end
  end

  describe "#to_xml" do
    it "should return the raw SOAP response body" do
      subject.to_xml.should == probe_response
    end
  end

  describe "#doc" do
    it "returns a Nokogiri::XML::Document for the SOAP response XML" do
      subject.doc.should be_a(Nokogiri::XML::Document)
    end
  end

  describe "#xpath" do
    it "permits XPath access to elements in the request" do
      subject.xpath("//a:Address").first.inner_text.
        should == "urn:uuid:0b679890-fc54-14ba-d428-f73b3e7c2400"
      subject.xpath("//d:ProbeMatch/d:XAddrs").first.inner_text.
        should == "http://10.221.222.74/onvif/device_service"
    end
  end
end
