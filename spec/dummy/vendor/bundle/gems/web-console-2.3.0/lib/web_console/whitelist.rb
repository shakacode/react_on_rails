require 'ipaddr'

module WebConsole
  # Whitelist of allowed networks that can access Web Console.
  #
  # Networks are represented by standard IPAddr and can be either IPv4 or IPv6
  # networks.
  class Whitelist
    # IPv4 and IPv6 localhost should be always whitelisted.
    ALWAYS_WHITELISTED_NETWORKS = %w( 127.0.0.0/8 ::1 )

    def initialize(networks = nil)
      @networks = normalize_networks(networks).map(&method(:coerce_network_to_ipaddr)).uniq
    end

    def include?(network)
      @networks.any? { |whitelist| whitelist.include?(network.to_s) }
    end

    def to_s
      @networks.map(&method(:human_readable_ipaddr)).join(', ')
    end

    private

      def normalize_networks(networks)
        Array(networks).concat(ALWAYS_WHITELISTED_NETWORKS)
      end

      def coerce_network_to_ipaddr(network)
        if network.is_a?(IPAddr)
          network
        else
          IPAddr.new(network)
        end
      end

      def human_readable_ipaddr(ipaddr)
        ipaddr.to_range.to_s.split('..').uniq.join('/')
      end
  end
end
