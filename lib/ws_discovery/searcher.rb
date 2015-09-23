require_relative 'multicast_connection'
require_relative 'response'
require 'semantic_logger'
require 'builder'
require 'uuid'

class WSDiscovery::Searcher < WSDiscovery::MulticastConnection
  include SemanticLogger::Loggable
  # @return [EventMachine::Channel] Provides subscribers with responses from
  #   their search request.
  attr_reader :discovery_responses

  # @param [Hash] options The options for the probe.
  # @option options [Hash<String>] :env_namespaces Additional envelope namespaces.
  # @option options [Hash<String>] :type_attributes Type attributes.
  # @option options [String] :types Types.
  # @option options [Hash<String>] :scope_attributes Scope attributes.
  # @option options [String] :scopes Scopes.
  # @option options [Fixnum] :ttl TTL for the probe.
  def initialize(options={})
    options[:ttl] ||= TTL

    @search = probe(options)

    super options[:ttl]
  end

  # This is the callback called by EventMachine when it receives data on the
  # socket that's been opened for this connection.  In this case, the method
  # parses the probe matches into WSDiscovery::Responses and adds them to the
  # appropriate EventMachine::Channel (provided as accessor methods).  This
  # effectively means that in each Channel, you get a WSDiscovery::Response
  # for each response that comes in on the socket.
  #
  # @param [String] response The data received on this connection's socket.
  def receive_data(response)
    ip, port = peer_info
    logger.info "<#{self.class}> Response from #{ip}:#{port}:\n#{response}\n"
    parsed_response = parse(response)
    @discovery_responses << parsed_response
  end

  # Converts the headers to a set of key-value pairs.
  #
  # @param [String] data The data to convert.
  # @return [WSDiscovery::Response] The converted data.
  def parse(data)
    WSDiscovery::Response.new(data)
  end

  # Sends the probe that was built during init.  Logs what was sent if the
  # send was successful.
  def post_init
    if send_datagram(@search, MULTICAST_IP, MULTICAST_PORT) > 0
      WSDiscovery::Searcher.log("Sent datagram search:\n#{@search}")
    end
  end

  # Probe for target services supporting WS-Discovery.
  #
  # @param [Hash] options The options for the probe.
  # @option options [Hash<String>] :env_namespaces Additional envelope namespaces.
  # @option options [Hash<String>] :type_attributes Type attributes.
  # @option options [String] :types Types.
  # @option options [Hash<String>] :scope_attributes Scope attributes.
  # @option options [String] :scopes Scopes.
  # @return [String] Probe SOAP message.
  def probe(options={})
    namespaces = {
      'xmlns:a' => 'http://schemas.xmlsoap.org/ws/2004/08/addressing',
      'xmlns:d' => 'http://schemas.xmlsoap.org/ws/2005/04/discovery',
      'xmlns:s' => 'http://www.w3.org/2003/05/soap-envelope'
    }
    namespaces.merge! options[:env_namespaces] if options[:env_namespaces]

    Builder::XmlMarkup.new.s(:Envelope, namespaces) do |xml|
      xml.s(:Header) do |xml|
        xml.a(:Action, 'http://schemas.xmlsoap.org/ws/2005/04/discovery/Probe')
        xml.a(:MessageID, "uuid:#{UUID.generate}")
        xml.a(:To, 'urn:schemas-xmlsoap-org:ws:2005:04:discovery')
      end

      xml.s(:Body) do |xml|
        xml.d(:Probe) do
          xml.d(:Types, options[:type_attributes], options[:types])
          xml.d(:Scopes, options[:scope_attributes], options[:scopes])
        end
      end
    end
  end
end
