require 'nokogiri'
require 'nori'
require_relative 'error'

module WSDiscovery

  # Represents the probe response.
  class Response

    attr_accessor :response

    # @param [String] response Text of the response to a WSDiscovery probe.
    def initialize(response)
      @response = response
    end

    # Shortcut accessor for the SOAP response body Hash.
    #
    # @param [Symbol] key The key to access in the body Hash.
    # @return [Hash,String] The accessed value.
    def [](key)
      body[key]
    end

    # Returns the SOAP response header as a Hash.
    #
    # @return [Hash] SOAP response header.
    # @raise [WSDiscovery::Error] If unable to parse response.
    def header
      unless hash.has_key? :envelope
        raise WSDiscovery::Error, "Unable to parse response body '#{to_xml}'"
      end

      hash[:envelope][:header]
    end

    # Returns the SOAP response body as a Hash.
    #
    # @return [Hash] SOAP response body.
    # @raise [WSDiscovery::Error] If unable to parse response.
    def body
      unless hash.has_key? :envelope
        raise WSDiscovery::Error, "Unable to parse response body '#{to_xml}'"
      end

      hash[:envelope][:body]
    end

    alias to_hash body

    # Returns the complete SOAP response XML without normalization.
    #
    # @return [Hash] Complete SOAP response Hash.
    def hash
      @hash ||= nori.parse(to_xml)
    end

    # Returns the SOAP response XML.
    #
    # @return [String] Raw SOAP response XML.
    def to_xml
      response
    end

    # Returns a Nokogiri::XML::Document for the SOAP response XML.
    #
    # @return [Nokogiri::XML::Document] Document for the SOAP response.
    def doc
      @doc ||= Nokogiri::XML(to_xml)
    end

    # Returns an Array of Nokogiri::XML::Node objects retrieved with the given +path+.
    # Automatically adds all of the document's namespaces unless a +namespaces+ hash is provided.
    #
    # @param [String] path XPath to search.
    # @param [Hash<String>] namespaces Namespaces to append.
    def xpath(path, namespaces = nil)
      doc.xpath(path, namespaces || xml_namespaces)
    end

    private

    # XML Namespaces from the Document.
    #
    # @return [Hash] Namespaces from the Document.
    def xml_namespaces
      @xml_namespaces ||= doc.collect_namespaces
    end

    # Returns a Nori parser.
    #
    # @return [Nori] Nori parser.
    def nori
      return @nori if @nori

      nori_options = {
        strip_namespaces: true,
        convert_tags_to: lambda { |tag| tag.snake_case.to_sym }
      }

      @nori = Nori.new(nori_options)
    end
  end
end
