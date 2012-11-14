maintainer        "Rackspace US, Inc."
license           "Apache 2.0"
description       "Installs and configures Openstack Swift"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version           "1.0.10"
recipe            "swift::account-server", "Installs the swift account server"
recipe            "swift::object-server", "Installs the swift object server"
recipe            "swift::proxy-server", "Installs the swift proxy server"
recipe            "swift::container-server", "Installs the swift container server"

%w{ubuntu fedora redhat centos scientific}.each do |os|
  supports os
end

%w{osops-utils dsh keystone collectd-graphite apt monitoring sysctl}.each do |dep|
  depends dep
end
