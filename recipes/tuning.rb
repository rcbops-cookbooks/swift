sysctl_multi "swift" do
  instructions "net.ipv4.tcp_tw_reuse" => "1", "net.ipv4.ip_local_port_range" => "10000 61000", "net.ipv4.tcp_syncookies" => "0", "net.ipv4.tcp_fin_timeout" => "30"
end
