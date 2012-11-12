require 'nokogiri'
require 'nori'

Nori.configure do |config|
  config.strip_namespaces = true
  config.convert_tags_to { |tag| tag.snakecase.to_sym }
end

module WSDiscovery

  # Represents the probe response.
  class Response

    def initialize(response)
      self.response = response
    end

    attr_accessor :response

    # Shortcut accessor for the SOAP response body Hash.
    def [](key)
      body[key]
    end

    # Returns the SOAP response header as a Hash.
    def header
      unless hash.has_key? :envelope
        raise WSDiscovery::Error, "Unable to parse response body '#{to_xml}'"
      end

      hash[:envelope][:header]
    end

    # Returns the SOAP response body as a Hash.
    def body
      unless hash.has_key? :envelope
        raise WSDiscovery::Error, "Unable to parse response body '#{to_xml}'"
      end

      hash[:envelope][:body]
    end

    alias to_hash body

    # Traverses the SOAP response body Hash for a given +path+ of Hash keys and returns
    # the value as an Array. Defaults to return an empty Array in case the path does not
    # exist or returns nil.
    def to_array(*path)
      result = path.inject body do |memo, key|
        return [] unless memo[key]
        memo[key]
      end

      result.kind_of?(Array) ? result.compact : [result].compact
    end

    # Returns the complete SOAP response XML without normalization.
    def hash
      @hash ||= Nori.parse(to_xml)
    end

    # Returns the SOAP response XML.
    def to_xml
      response
    end

    # Returns a <tt>Nokogiri::XML::Document</tt> for the SOAP response XML.
    def doc
      @doc ||= Nokogiri::XML(to_xml)
    end

    # Returns an Array of <tt>Nokogiri::XML::Node</tt> objects retrieved with the given +path+.
    # Automatically adds all of the document's namespaces unless a +namespaces+ hash is provided.
    def xpath(path, namespaces = nil)
      doc.xpath(path, namespaces || xml_namespaces)
    end

    private

    def xml_namespaces
      @xml_namespaces ||= doc.collect_namespaces
    end
  end
end
