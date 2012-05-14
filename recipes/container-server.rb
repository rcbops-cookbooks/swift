#
# Cookbook Name:: swift
# Recipe:: swift-container-server
#
# Copyright 2012, Rackspace Hosting
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "swift::common"
include_recipe "swift::storage-common"
include_recipe "swift::disks"

if platform?(%w{fedora})
  # fedora, maybe other rhel-ish dists
  swift_container_package = "openstack-swift-container"
  service_prefix = "openstack-swift-"
  service_suffix = ".service"

  # global
  service_provider = Chef::Provider::Service::Systemd
  package_override_options = ""
else
  # debian, ubuntu, other debian-ish
  swift_container_package = "swift-container"
  service_prefix = ""
  service_suffix = ""

  # global
  service_provider = Chef::Provider::Service::Upstart
  package_override_options = "-o Dpkg::Options:='--force-confold' -o Dpkg::Option:='--force-confdef'"
end

package swift_container_package do
  action :upgrade
  options package_override_options
end

# epel/f-17 missing init scripts for the non-major services.
# https://bugzilla.redhat.com/show_bug.cgi?id=807170
%w{auditor updater replicator}.each do |svc|
  template "/etc/systemd/system/openstack-swift-container-#{svc}.service" do
    owner "root"
    group "root"
    mode "0644"
    source "simple-systemd-config.erb"
    variables({ :description => "OpenStack Object Storage (swift) - " +
                "Container #{svc.capitalize}",
                :user => "swift",
                :exec => "/usr/bin/swift-container-#{svc} " +
                "/etc/swift/container-server.conf"
              })
    only_if { platform?(%w{fedora}) }
  end
end


%w{swift-container swift-container-auditor swift-container-replicator swift-container-updater}.each do |svc|
  service svc do
    service_name "#{service_prefix}#{svc}#{service_suffix}"
    provider service_provider
    supports :status => true, :restart => true
    action [:enable, :start]
    only_if "[ -e /etc/swift/container-server.conf ] && [ -e /etc/swift/container.ring.gz ]"
  end
end

template "/etc/swift/container-server.conf" do
  source "container-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  notifies :restart, "service[swift-container]", :immediately
  notifies :restart, "service[swift-container-replicator]", :immediately
  notifies :restart, "service[swift-container-updater]", :immediately
  notifies :restart, "service[swift-container-auditor]", :immediately
end

