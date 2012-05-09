#
# Cookbook Name:: swift
# Recipe:: memcached
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

bind_address = IPManagement.get_ip_for_net("swift-private", node)

if platform?(%w{fedora})
  # fedora, maybe other rhel-ish dists
  memcached_package_options = ""
  memcached_config_file = "/etc/sysconfig/memcached"
  memcached_sed_command = "'s/OPTIONS.*/OPTIONS=\"-l #{bind_address}\"/'"
else
  # debianish
  memcached_package_options = "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
  memcached_config_file = "/etc/memcached.conf"
  memcached_sed_command = "'s/^-l .*/-l #{bind_address}/'"
end

package "memcached" do
  action :upgrade
  options memcached_package_options
end

service "memcached" do
  supports :status => true, :restart => true
  action :enable
end

execute "set listening port" do
  command "sed -i #{memcached_config_file} -e #{memcached_sed_command}"
  not_if "grep -q -- '-l #{bind_address}' #{memcached_config_file}"
  notifies :restart, resources(:service => "memcached"), :immediately
  action :run
end
