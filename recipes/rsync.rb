#
# Cookbook Name:: swift
# Recipe:: rsync
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

if platform?(%w{fedora})
  # fedora, maybe other rhel-ish dists
  swift_force_options = ""
  rsync_service_name = "rsync"
  rsync_package = "rsync"
else
  # debian, ubuntu, other debian-ish
  swift_force_options = "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
  rsync_service_name = "rsync"
  rsync_package = "rsyncd"
end

package "rsyncd" do
  package_name = rsync_package
  action :upgrade
  options swift_force_options
end

# epel/f-17 broken: https://bugzilla.redhat.com/show_bug.cgi?id=737710
cookbook_file "/etc/systemd/system/rsync.service" do
  owner "root"
  group "root"
  mode "0644"
  source "rsync.service"
  action :create
  only_if { platform?(%w{fedora}) }
end

# FIXME: chicken and egg
service "rsync" do
  service_name rsync_service_name
  supports :status => false, :restart => true
  action [ :enable, :start ]
  not_if "[ ! -f /etc/rsyncd.conf ]"
end

template "/etc/rsyncd.conf" do
  source "rsyncd.conf.erb"
  mode "0644"
  notifies :restart, resources(:service => "rsync"), :immediately
end

execute "enable rsync" do
  command "sed -i 's/RSYNC_ENABLE=false/RSYNC_ENABLE=true/' /etc/default/rsync"
  only_if "grep -q 'RSYNC_ENABLE=false' /etc/default/rsync"
  notifies :restart, resources(:service => "rsync"), :immediately
  action :run
  not_if { platform?(%w{fedora}) }
end


