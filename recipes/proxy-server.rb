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

package "swift-proxy" do
  action :upgrade
  options "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
end

package "python-swauth" do
  action :upgrade
  options "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'"
  only_if { node["swift"]["authmode"] == :swauth }
end

service "swift-proxy" do
  supports :status => true, :restart => true
  action :enable
  only_if "[ -e /etc/swift/proxy-server.conf ] && [ -e /etc/swift/object.ring.gz ]"
end

if node["swift"]["authmode"] == "keystone"
  if Chef::Config[:solo]
    Chef::Log.warn("This recipe uses search. Chef Solo does not support search.")
  else
    keystone, start, arbitary_value = Chef::Search::Query.new.search(:node, "roles:keystone AND chef_environment:#{node.chef_environment}")
    if keystone.length > 0
      Chef::Log.info("registry/keystone: using search")
      keystone_api_ip = keystone[0]['keystone']['api_ipaddress']
      keystone_service_port = keystone[0]['keystone']['service_port']
      keystone_admin_port = keystone[0]['keystone']['admin_port']
      keystone_admin_token = keystone[0]['keystone']['admin_token']
    else
      Chef::Log.info("registry/keystone: NOT using search")
      keystone_api_ip = node['keystone']['api_ipaddress']
      keystone_service_port = node['keystone']['service_port']
      keystone_admin_port = node['keystone']['admin_port']
      keystone_admin_token = node['keystone']['admin_token']
    end
  end

  # Register Service Tenant
  keystone_register "Register Service Tenant" do
    auth_host keystone_api_ip
    auth_port keystone_admin_port
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone_admin_token
    tenant_name node["swift"]["service_tenant_name"]
    tenant_description "Service Tenant"
    tenant_enabled "true" # Not required as this is the default
    action :create_tenant
  end

  # Register Service User
  keystone_register "Register Service User" do
    auth_host keystone_api_ip
    auth_port keystone_admin_port
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone_admin_token
    tenant_name node["swift"]["service_tenant_name"]
    user_name node["swift"]["service_user"]
    user_pass node["swift"]["service_pass"]
    user_enabled "true" # Not required as this is the default
    action :create_user
  end

  ## Grant Admin role to Service User for Service Tenant ##
  keystone_register "Grant 'admin' Role to Service User for Service Tenant" do
    auth_host keystone_api_ip
    auth_port keystone_admin_port
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone_admin_token
    tenant_name node["swift"]["service_tenant_name"]
    user_name node["swift"]["service_user"]
    role_name node["swift"]["service_role"]
    action :grant_role
  end

  # Register Storage Service
  keystone_register "Register Storage Service" do
    auth_host keystone_api_ip
    auth_port keystone_admin_port
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone_admin_token
    service_name "swift"
    service_type "storage"
    service_description "Swift Object Storage Service"
    action :create_service
  end

  # Register Storage Endpoint
  keystone_register "Register Storage Endpoint" do
    auth_host keystone_api_ip
    auth_port keystone_admin_port
    auth_protocol "http"
    api_ver "/v2.0"
    auth_token keystone_admin_token
    service_type "storage"
    endpoint_region "RegionOne"
    endpoint_adminurl node["swift"]["api"]["adminURL"]
    endpoint_internalurl node["swift"]["api"]["internalURL"]
    endpoint_publicurl node["swift"]["api"]["publicURL"]
    action :create_endpoint
  end
end

template "/etc/swift/proxy-server.conf" do
  source "proxy-server.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  if node["swift"]["authmode"] == "keystone"
    variables(
      "authmode" => node["swift"]["authmode"],
      "bind_host" => node["swift"]["api"]["bind_address"],
      "bind_port" => node["swift"]["api"]["port"]
      "keystone_api_ipaddress" => keystone_api_ip,
      "keystone_service_port" => keystone_service_port,
      "keystone_admin_port" => keystone_admin_port,
      "service_tenant_name" => node["swift"]["service_tenant_name"],
      "service_user" => node["swift"]["service_user"],
      "service_pass" => node["swift"]["service_pass"]
    )
  else
    variables(
      "authmode" => node["swift"]["authmode"],
      "bind_host" => node["swift"]["api"]["bind_address"],
      "bind_port" => node["swift"]["api"]["port"]
    )
  end
  notifies :restart, resources(:service => "swift-proxy"), :immediately
end

