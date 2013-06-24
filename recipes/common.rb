#
# Cookbook Name:: swift
# Recipe:: swift-common
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
include_recipe "osops-utils"

class Chef::Recipe
  include DriveUtils
end

platform_options = node["swift"]["platform"]

git_service = get_access_endpoint("swift-management-server","swift","ring-repo")

platform_options["swift_packages"].each do |pkg|
  package pkg do
    action :install
  end
end

directory "/etc/swift" do
  action :create
  owner "swift"
  group "swift"
  mode "0700"
  only_if "/usr/bin/id swift"
end

file "/etc/swift/swift.conf" do
  action :create
  owner "swift"
  group "swift"
  mode "0700"
  content "[swift-hash]\nswift_hash_path_suffix=#{node['swift']['swift_hash']}\n"
  only_if "/usr/bin/id swift"
end

# need a shell to dsh, among other things
user "swift" do
  shell "/bin/bash"
  action :modify
  only_if "/usr/bin/id swift"
end

package "git" do
  action :install
end

# drop a ring puller script so we can dsh ring pulls
template "/etc/swift/pull-rings.sh" do
  source "pull-rings.sh.erb"
  owner "swift"
  group "swift"
  mode "0700"
  variables({
              :builder_ip => git_service["host"],
              :service_prefix => platform_options["service_prefix"]
            })
  only_if "/usr/bin/id swift"
end

execute "/etc/swift/pull-rings.sh" do
  cwd "/etc/swift"
  only_if "[ -x /etc/swift/pull-rings.sh ]"
end

template "/etc/sudoers.d/swift" do
  owner "root"
  group "root"
  mode "0440"
  variables({
              :node => node
            })
  action :nothing
end

keystone = get_settings_by_role("keystone-setup", "keystone")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone", "service-api")

template "/root/swift-openrc" do
  source "swift-openrc.erb"
  owner "swift"
  group "swift"
  mode "0600"
  vars = {
    "user" => keystone["admin_user"],
    "tenant" => keystone["users"][keystone["admin_user"]]["default_tenant"],
    "password" => keystone["users"][keystone["admin_user"]]["password"],
    "keystone_api_ipaddress" => ks_service_endpoint["host"],
    "keystone_service_port" => ks_service_endpoint["port"],
    "keystone_service_protocol" => ks_service_endpoint["scheme"],
    "auth_strategy" => "keystone",
  }
  variables(vars)
end

# README(shep): disk usage thresholds are performed by hardware::common
# devices = (node["swift"]["state"]["devs"] || {}).inject([]) { |ary, (k,v)| ary << v["mountpoint"] }

# Sysctl tuning
include_recipe "sysctl::default"
sysctl_multi "swift" do
  instructions("net.ipv4.tcp_tw_reuse" => "1",
               "net.ipv4.ip_local_port_range" => "10000 61000",
               "net.ipv4.tcp_syncookies" => "0",
               "net.ipv4.tcp_fin_timeout" => "30")
end
