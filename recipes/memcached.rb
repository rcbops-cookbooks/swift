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

if node["swift"]["authmode"] == :swauth then
  package "memcached" do
    action :upgrade
    options "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
  end

  service "memcached" do
    supports :status => true, :restart => true
    action :enable
  end

  # FIXME(rp): needs to listen appropriately, or be firewalled?
  execute "set listening port" do
    command "sed -i 's/-l 127.0.0.1/-l 0.0.0.0/' /etc/memcached.conf"
    only_if "grep -q -- '-l 127.0.0.1' /etc/memcached.conf"
    notifies :restart, resources(:service => "memcached"), :immediately
    action :run
  end
end
