require_relative 'ws-discovery/core_ext/socket_patch'
require 'eventmachine'
require 'log_switch'

require_relative 'ws-discovery/error'
require_relative 'ws-discovery/network_constants'
require_relative 'ws-discovery/searcher'

class SSDP
  extend LogSwitch
  include LogSwitch::Mixin
  include NetworkConstants

  self.logger.datetime_format = "%Y-%m-%d %H:%M:%S "

  # Opens a UDP socket on 0.0.0.0, on an ephemeral port, has UPnP::SSDP::Searcher
  # build and send the search request, then receives the responses.  The search
  # will stop after +response_wait_time+.
  #
  # @param [String] search_target
  # @param [Hash] options
  # @option options [Fixnum] response_wait_time
  # @option options [Fixnum] ttl
  # @option options [Fixnum] m_search_count
  # @return [Array<Hash>,UPnP::SSDP::Searcher] Returns a Hash that represents
  #   the headers from the M-SEARCH response.  Each one of these can be passed
  #   in to UPnP::ControlPoint::Device.new to download the device's
  #   description file, parse it, and interact with the device's devices
  #   and/or services.  If the reactor is already running this will return a
  #   a UPnP::SSDP::Searcher which will make its accessors available so you
  #   can get responses in real time.
  def self.search(search_target=:all, options={})
    response_wait_time = options[:response_wait_time] || 5
    ttl = options[:ttl] || TTL

    searcher_options = options

    responses = []
    search_target = search_target.to_upnp_s unless search_target.is_a? String

    multicast_searcher = proc do
      EM.open_datagram_socket('0.0.0.0', 0, UPnP::SSDP::Searcher, search_target,
        searcher_options)
    end

    if EM.reactor_running?
      return multicast_searcher.call
    else
      EM.run do
        ms = multicast_searcher.call

        ms.discovery_responses.subscribe do |notification|
          responses << notification
        end

        EM.add_timer(response_wait_time) { EM.stop }
        trap_signals
      end
    end

    responses.flatten
  end

  private

  # Traps INT, TERM, and HUP signals and stops the reactor.
  def self.trap_signals
    trap('INT') { EM.stop }
    trap('TERM') { EM.stop }
    trap('HUP') { EM.stop } if RUBY_PLATFORM !~ /mswin|mingw/
  end
end
