#
# Cookbook Name:: swift
# Recipe:: swift-proxy-server
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
include_recipe "swift::memcached"
include_recipe "osops-utils"

if platform?(%w{fedora})
  # fedora, maybe other rhel-ish dists
  swift_proxy_package = "openstack-swift-proxy"
  service_prefix = "openstack-"
  service_suffix = ".service"

  # global
  service_provider = Chef::Provider::Service::Systemd
  package_override_options = ""
else
  # debian, ubuntu, other debian-ish
  swift_proxy_package = "swift-proxy"
  service_prefix = ""
  service_suffix = ""

  # global
  service_provider = nil
  package_override_options = "-o Dpkg::Options:='--force-confold' -o Dpkg::Option:='--force-confdef'"
end

package swift_proxy_package do
  action :upgrade
  options package_override_options
end

package "python-swauth" do
  action :upgrade
  only_if { node["swift"]["authmode"] == "swauth" }
end

package "python-keystone" do
  action :upgrade
  only_if { node["swift"]["authmode"] == "keystone" }
end

service "swift-proxy" do
  service_name "#{service_prefix}swift-proxy#{service_suffix}"
  provider service_provider
  supports :status => true, :restart => true
  action [ :enable, :start ]
  only_if "[ -e /etc/swift/proxy-server.conf ] && [ -e /etc/swift/object.ring.gz ]"
end

if node["swift"]["authmode"] == "keystone"
  result = node

  if not Chef::Config[:solo]
    (result,*_), _, _ = Chef::Search::Query.new.search(:node, "roles:keystone AND chef_environment:#{node.chef_environment}")
    result = node if result.length <= 0
  end

  keystone = Hash[result["keystone"].select { |k,v| ["admin_port", "admin_token"].include?(k) }]

  # FIXME: this should really return ip and port
  keystone["api_ipaddress"]=IPManagement.get_access_ip_for_role("keystone", "swift-lb", node)

  # Register Service Tenant
  keystone_register "Register Service Tenant" do
    auth_host keystone["api_ipaddress"]
    auth_port keystone["admin_port"]
    auth_protocol "http"            # FIXME: bad smell
    api_ver "/v2.0"
    auth_token keystone["admin_token"]
    tenant_name node["swift"]["service_tenant_name"]
    tenant_description "Service Tenant"
    tenant_enabled "true" # Not required as this is the default
    action :create_tenant
  end

  # Register Service User
  keystone_register "Register Service User" do
    auth_host keystone["api_ipaddress"]
    auth_port keystone["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone["admin_token"]
    tenant_name node["swift"]["service_tenant_name"]
    user_name node["swift"]["service_user"]
    user_pass node["swift"]["service_pass"]
    user_enabled "true" # Not required as this is the default
    action :create_user
  end

  ## Grant Admin role to Service User for Service Tenant ##
  keystone_register "Grant 'admin' Role to Service User for Service Tenant" do
    auth_host keystone["api_ipaddress"]
    auth_port keystone["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone["admin_token"]
    tenant_name node["swift"]["service_tenant_name"]
    user_name node["swift"]["service_user"]
    role_name node["swift"]["service_role"]
    action :grant_role
  end

  # Register Storage Service
  keystone_register "Register Storage Service" do
    auth_host keystone["api_ipaddress"]
    auth_port keystone["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone["admin_token"]
    service_name "swift"
    service_type "object-store"
    service_description "Swift Object Storage Service"
    action :create_service
  end

  # Register Storage Endpoint
  keystone_register "Register Storage Endpoint" do
    auth_host keystone["api_ipaddress"]
    auth_port keystone["admin_port"]
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone["admin_token"]
    service_type "object-store"
    endpoint_region "RegionOne"
    endpoint_adminurl node["swift"]["api"]["adminURL"]
    endpoint_internalurl node["swift"]["api"]["internalURL"]
    endpoint_publicurl node["swift"]["api"]["publicURL"]
    action :create_endpoint
  end
end

require "pp"
Chef::Log.info("Ips for memcache: #{PP.pp(IPManagement.get_ips_for_role('swift-proxy-server','swift-private', node), dump='')}")


template "/etc/swift/proxy-server.conf" do
  source "proxy-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  if node["swift"]["authmode"] == "keystone"
    variables("authmode" => node["swift"]["authmode"],
              "bind_host" => IPManagement.get_ip_for_net("swift-public", node),
              "bind_port" => node["swift"]["api"]["port"],
              "keystone_api_ipaddress" => keystone["api_ipaddress"],
              "keystone_service_port" => keystone["service_port"],
              "keystone_admin_port" => keystone["admin_port"],
              "service_tenant_name" => node["swift"]["service_tenant_name"],
              "service_user" => node["swift"]["service_user"],
              "service_pass" => node["swift"]["service_pass"],
              "memcache_servers" => IPManagement.get_ips_for_role("swift-proxy-server","swift-private", node)
              )
  else
    variables("authmode" => node["swift"]["authmode"],
              "bind_host" => IPManagement.get_ip_for_net("swift-public", node),
              "bind_port" => node["swift"]["api"]["port"],
              "memcache_servers" => IPManagement.get_ips_for_role("swift-proxy-server","swift-private", node)
              )
  end
  notifies :restart, resources(:service => "swift-proxy"), :immediately
end

