require 'spec_helper'
require 'ws_discovery'

describe WSDiscovery do
  subject { WSDiscovery }

  describe '.search' do
    let(:multicast_searcher) do
      searcher = double "WSDiscovery::Searcher"
      searcher.stub_chain(:discovery_responses, :subscribe).and_yield(%w[one two])

      searcher
    end

    before do
      EM.stub(:run).and_yield
      EM.stub(:add_timer)
      EM.stub(:open_datagram_socket).and_return multicast_searcher
    end

    context "reactor is already running" do
      it "returns a WSDiscovery::Searcher" do
        EM.stub(:reactor_running?).and_return true
        subject.search.should == multicast_searcher
      end
    end

    context "reactor is not already running" do
      it "returns an Array of responses" do
        EM.stub(:add_shutdown_hook).and_yield
        subject.search.should == %w[one two]
      end

      it "opens a UDP socket on '0.0.0.0', port 0" do
        EM.stub(:add_shutdown_hook)
        EM.should_receive(:open_datagram_socket).with('0.0.0.0', 0,
          WSDiscovery::Searcher, {})
        subject.search
      end
    end
  end
end

