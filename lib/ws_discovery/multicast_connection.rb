require_relative 'core_ext/socket_patch'
require_relative 'network_constants'
require_relative 'error'
require 'ipaddr'
require 'socket'
require 'eventmachine'

module WSDiscovery
  class MulticastConnection < EventMachine::Connection
    include WSDiscovery::NetworkConstants

    # @param [Fixnum] ttl The TTL value to use when opening the UDP socket
    #   required for WSDiscovery actions.
    def initialize ttl=TTL
      @ttl = ttl
      @discovery_responses = EM::Channel.new

      setup_multicast_socket
    end

    # Gets the IP and port from the peer that just sent data.
    #
    # @return [Array<String,Fixnum>] The IP and port.
    def peer_info
      peer_bytes = get_peername[2, 6].unpack("nC4")
      port = peer_bytes.first.to_i
      ip = peer_bytes[1, 4].join(".")

      [ip, port]
    end

    # Sets Socket options to allow for multicasting.  If ENV["RUBY_UPNP_ENV"] is
    # equal to "testing", then it doesn't turn off multicast looping.
    def setup_multicast_socket
      set_membership(IPAddr.new(MULTICAST_IP).hton + IPAddr.new('0.0.0.0').hton)
      set_multicast_ttl(@ttl)
      set_ttl(@ttl)

      unless ENV["RUBY_UPNP_ENV"] == "testing"
        switch_multicast_loop :off
      end
    end

    # @param [String] membership The network byte ordered String that represents
    #   the IP(s) that should join the membership group.
    def set_membership(membership)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_ADD_MEMBERSHIP, membership)
    end

    # @param [Fixnum] ttl TTL to set IP_MULTICAST_TTL to.
    def set_multicast_ttl(ttl)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_TTL, [ttl].pack('i'))
    end

    # @param [Fixnum] ttl TTL to set IP_TTL to.
    def set_ttl(ttl)
      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_TTL, [ttl].pack('i'))
    end

    # @param [Symbol] on_off Turn on/off multicast looping.  Supply :on or :off.
    def switch_multicast_loop(on_off)
      hex_value = case on_off
      when :on, "\001"
        "\001"
      when :off, "\000"
        "\000"
      else
        raise WSDiscovery::Error, "Can't switch IP_MULTICAST_LOOP to '#{on_off}'"
      end

      set_sock_opt(Socket::IPPROTO_IP, Socket::IP_MULTICAST_LOOP, hex_value)
    end
  end
end
