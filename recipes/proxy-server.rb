#
# Cookbook Name:: swift
# Recipe:: proxy-server
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

include_recipe "swift::common"
include_recipe "memcached-openstack"
include_recipe "osops-utils"

# Find the node that ran the swift-setup recipe and grab his passswords
if Chef::Config[:solo]
  Chef::Application.fatal! "This recipe uses search. Chef Solo does not support search."
else
  if node.run_list.expand(node.chef_environment).recipes.include?("swift::setup")
    Chef::Log.info("I ran the swift::setup so I will use my own swift passwords")
  else
    setup = search(:node, "chef_environment:#{node.chef_environment} AND roles:swift-setup")
    if setup.length == 0
      Chef::Application.fatal! "You must have run the swift::setup recipe (on this or another node) before running the swift::proxy recipe on this node"
    elsif setup.length == 1
      Chef::Log.info "Found swift::setup node: #{setup[0].name}"
      node.set["swift"]["service_pass"] = setup[0]["swift"]["service_pass"]
    elsif setup.length >1
      Chef::Application.fatal! "You have multiple nodes in your environment that have run swift-setup, and that is not allowed"
    end
  end
end

platform_options = node["swift"]["platform"]

# install platform-specific packages
platform_options["proxy_packages"].each do |pkg|
  package pkg do
    action :install
    options platform_options["override_options"]
  end
end

package "python-swauth" do
  action :install
  only_if { node["swift"]["authmode"] == "swauth" }
end

package "python-swift-informant" do
  action :install
  only_if { node["swift"]["use_informant"] }
end

package "python-keystone" do
  action :install
  only_if { node["swift"]["authmode"] == "keystone" }
end

directory "/var/cache/swift" do
  owner "swift"
  group "swift"
  mode 0600
end

swift_proxy_service = platform_options["service_prefix"] + "swift-proxy" + platform_options["service_suffix"]
service "swift-proxy" do
  # openstack-swift-proxy.service on fedora-17, swift-proxy on ubuntu
  service_name swift_proxy_service
  provider platform_options["service_provider"]
  supports :status => true, :restart => true
  action [ :enable, :start ]
  only_if "[ -e /etc/swift/proxy-server.conf ] && [ -e /etc/swift/object.ring.gz ]"
end

# Find all our endpoint info

# if swift is configured to use monitoring then get the endpoint.  If it is
# not then we need to fake the endpoint so the template for proxy-server.conf
# lays down the config file correctly.
if node["swift"]["use_informant"] then
    statsd_endpoint = get_access_endpoint("graphite", "statsd", "statsd")
else
    statsd_endpoint={"host"=>"undefined","port"=>"undefined"}
end

memcache_endpoints = get_realserver_endpoints("memcached", "memcached", "cache")

# We'll just use a single memcache if we're set up as a management
# server, so as not to pollute the production memcache servers
if node["roles"].include?("swift-management-server")
  memcache_endpoints = [ get_bind_endpoint("memcached","cache") ]
end

memcache_servers = memcache_endpoints.collect do |endpoint|
  "#{endpoint["host"]}:#{endpoint["port"]}"
end.join(",")

proxy_bind = get_bind_endpoint("swift", "proxy")
proxy_access = get_access_endpoint("swift-proxy-server", "swift", "proxy")
ks_admin = get_access_endpoint("keystone-api","keystone","admin-api")
ks_service = get_access_endpoint("keystone-api","keystone","service-api")

template "/etc/swift/proxy-server.conf" do
  source "proxy-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  variables("authmode" => node["swift"]["authmode"],
            "bind_host" => proxy_bind["host"],
            "bind_port" => proxy_bind["port"],
            "keystone_api_ipaddress" => ks_admin["host"],
            "keystone_service_port" => ks_service["port"],
            "keystone_service_protocol" => ks_service["scheme"],
            "keystone_admin_port" => ks_admin["port"],
            "keystone_admin_protocol" => ks_admin["scheme"],
            "service_tenant_name" => node["swift"]["service_tenant_name"],
            "service_user" => node["swift"]["service_user"],
            "service_pass" => node["swift"]["service_pass"],
            "memcache_servers" => memcache_servers,
            "bind_host" => proxy_bind["host"],
            "bind_port" => proxy_bind["port"],
            "cluster_endpoint" => proxy_access["uri"],
            "use_informant" => node["swift"]["use_informant"],
            "statsd_host" => statsd_endpoint["host"],
            "statsd_port" => statsd_endpoint["port"]
            )
  notifies :restart, "service[swift-proxy]", :immediately
end
