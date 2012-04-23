template "/etc/swift/drive-audit.conf" do
  source "drive-audit.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
end

cron "drive-audit" do
  hour node["swift"]["audit_hour"]
  minute "10"
  command "swift-drive-audit /etc/swift/drive-audit.conf"
end
