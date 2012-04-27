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

package "swift-account" do
  action :upgrade
  options "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
end

%W(swift-account swift-account-auditor swift-account-reaper swift-account-replicator).each do |svc|
  service svc do
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

