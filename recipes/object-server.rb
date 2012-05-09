#
# Cookbook Name:: swift
# Recipe:: swift-object-server
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
  swift_object_package = "openstack-swift-object"
  swift_force_options = ""
  swift_object_service_prefix = "openstack-"
else
  # debian, ubuntu, other debian-ish
  swift_object_package = "swift-object"
  swift_force_options = "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
  swift_object_service_prefix = ""
end

package swift_object_package do
  action :upgrade
  options swift_force_options
end

%W(swift-object swift-object-replicator swift-object-auditor swift-object-updater).each do |svc|
  service svc do
    service_name "#{swift_object_service_prefix}#{svc}"
    supports :status => true, :restart => true
    action :enable
    only_if "[ -e /etc/swift/object-server.conf ] && [ -e /etc/swift/object.ring.gz ]"
  end
end

template "/etc/swift/object-server.conf" do
  source "object-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  notifies :restart, "service[swift-object]", :immediately
  notifies :restart, "service[swift-object-replicator]", :immediately
  notifies :restart, "service[swift-object-updater]", :immediately
  notifies :restart, "service[swift-object-auditor]", :immediately
end

cron "swift-recon" do
  minute "*/5"
  command "swift-recon-cron /etc/swift/object-server.conf"
  user "swift"
end
