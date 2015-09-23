require 'spec_helper'
require 'ws_discovery'

describe WSDiscovery do
  subject { WSDiscovery }

  describe '.search' do
    let(:multicast_searcher) do
      searcher = double "WSDiscovery::Searcher"
      allow(searcher).to receive_message_chain(:discovery_responses, :subscribe).and_yield(%w[one two])

      searcher
    end

    before do
      allow(EM).to receive(:run).and_yield
      allow(EM).to receive(:add_timer)
      allow(EM).to receive(:open_datagram_socket).and_return multicast_searcher
    end

    context "reactor is already running" do
      it "returns a WSDiscovery::Searcher" do
        allow(EM).to receive(:reactor_running?).and_return true
        expect(subject.search).to eql multicast_searcher
      end
    end

    context "reactor is not already running" do
      it "returns an Array of responses" do
        allow(EM).to receive(:add_shutdown_hook).and_yield
        expect(subject.search).to eql %w[one two]
      end

      it "opens a UDP socket on '0.0.0.0', port 0" do
        allow(EM).to receive(:add_shutdown_hook)
        expect(EM).to receive(:open_datagram_socket).with('0.0.0.0', 0,
          WSDiscovery::Searcher, {})
        subject.search
      end
    end
  end
end

