#
# Cookbook Name:: swift
# Recipe:: memcached
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


case node['platform']
when "redhat", "centos", "fedora"
  platform_options = node["swift"]["platform"]
when "ubuntu"
  platform_options = node["swift"]["platform"][node['package_component']]
end

bind_address = get_bind_endpoint("swift","memcache")["host"]

if platform?(%w{fedora})
  memcached_sed_command = "'s/OPTIONS.*/OPTIONS=\"-l #{bind_address}\"/'"
else
  memcached_sed_command = "'s/^-l .*/-l #{bind_address}/'"
end

package "memcached" do
  action :install
  options platform_options["override_options"]
end

service "memcached" do
  supports :status => true, :restart => true
  action :enable
end

execute "set listening port" do
  command "sed -i #{platform_options["memcached_config_file"]} -e #{memcached_sed_command}"
  not_if "grep -q -- '-l #{bind_address}' #{platform_options["memcached_config_file"]}"
  notifies :restart, resources(:service => "memcached"), :immediately
  action :run
end
