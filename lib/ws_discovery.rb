require_relative 'ws_discovery/core_ext/socket_patch'
require 'eventmachine'

require_relative 'ws_discovery/error'
require_relative 'ws_discovery/network_constants'
require_relative 'ws_discovery/searcher'

module WSDiscovery
  include NetworkConstants

  # Opens a UDP socket on 0.0.0.0, on an ephemeral port, has WSDiscovery::Searcher
  # build and send the search request, then receives the responses.  The search
  # will stop after +response_wait_time+.
  #
  # @param [Hash] options
  # @option options [Fixnum] env_namespaces
  # @option options [Fixnum] type_attributes
  # @option options [Fixnum] types
  # @option options [Fixnum] scope_attributes
  # @option options [Fixnum] scopes
  # @return [Array<WSDiscovery::Response>,WSDiscovery::Searcher] Returns an
  # Array of probe responses. If the reactor is already running this will return
  # a WSDiscovery::Searcher which will make its accessors available so you can
  # get responses in real time.
  def self.search(options={})
    response_wait_time = options[:response_wait_time] || 5
    responses = []

    multicast_searcher = proc do
      EM.open_datagram_socket('0.0.0.0', 0, WSDiscovery::Searcher, options)
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
