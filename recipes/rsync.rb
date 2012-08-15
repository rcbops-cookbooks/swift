#
# Cookbook Name:: swift
# Recipe:: rsync
#
# Copyright 2012, Rackspace US, Inc.
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

platform_options = node["swift"]["platform"]

platform_options["rsync_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["override_options"]
  end
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
  supports :status => false, :restart => true
  action [ :enable, :start ]
  only_if "[ -f /etc/rsyncd.conf ]"
end

monitoring_metric "rysnc" do
  type "proc"
  proc_name "rsync"
  proc_regex "rsync"

  alarms(:failure_min => 0.0)
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
