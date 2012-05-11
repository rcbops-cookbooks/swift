#
# Cookbook Name:: swift
# Recipe:: swift-account-server
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
  swift_account_package = "openstack-swift-account"
  swift_force_options = ""
  service_prefix = "openstack-"
  service_suffix = ".service"

  # global
  service_provider = Chef::Provider::Service::Systemd
  package_override_options = ""
else
  # debian, ubuntu, other debian-ish
  swift_account_package = "swift-account"
  service_prefix = ""
  service_prefix = ""

  # global
  service_provider = nil
  package_override_options = "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
end

package swift_account_package do
  action :upgrade
  options package_override_options
end

# epel/f-17 missing init scripts for the non-major services.
# https://bugzilla.redhat.com/show_bug.cgi?id=807170
%w{auditor reaper replicator}.each do |svc|
  template "/etc/systemd/system/openstack-swift-account-#{svc}.service" do
    owner "root"
    group "root"
    mode "0644"
    source "simple-systemd-config.erb"
    variables({ :description => "OpenStack Object Storage (swift) - " +
                "Account #{svc.capitalize}",
                :user => "swift",
                :exec => "/usr/bin/swift-account-${svc} " +
                "/etc/swift/account-server.conf"
              })
    only_if { platform?(%w{fedora}) }
  end
end

%w{swift-account swift-account-auditor swift-account-reaper swift-account-replicator}.each do |svc|
  service svc do
    service_name "#{service_prefix}#{svc}#{service_suffix}"
    provider service_provider
    supports :status => true, :restart => true
    action :enable
    only_if "[ -e /etc/swift/account-server.conf ] && [ -e /etc/swift/account.ring.gz ]"
  end
end

template "/etc/swift/account-server.conf" do
  source "account-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  notifies :restart, "service[swift-account]", :immediately
  notifies :restart, "service[swift-account-auditor]", :immediately
  notifies :restart, "service[swift-account-reaper]", :immediately
  notifies :restart, "service[swift-account-replicator]", :immediately
end

