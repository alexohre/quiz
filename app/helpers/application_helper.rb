require 'socket'

module ApplicationHelper
  def local_network_address
    ip = Socket.ip_address_list.find { |ai| ai.ipv4? && !ai.ipv4_loopback? && ai.ipv4_private? }&.ip_address || "127.0.0.1"
    port = request.port rescue 3000
    "#{ip}:#{port}"
  end
end
