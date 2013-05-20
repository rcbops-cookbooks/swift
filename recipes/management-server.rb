#
# Cookbook Name:: swift
# Recipe:: management-server
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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "swift::common"

node.set_unless['swift']['dispersion_service_pass'] = secure_password

# FIXME: This should probably be a role (ring-builder?), so you don't end up
# with multiple repos!
include_recipe "swift::ring-repo"

# Apply hot patches for dispersion populate and report interop with keystone
include_recipe "swift::swift-dispersion-patch"

platform_options = node["swift"]["platform"]

dsh_group "swift-storage" do
  admin_user "root"
  network "swift"
end

ks_admin_endpoint = get_access_endpoint("keystone-api", "keystone", "admin-api")
ks_service_endpoint = get_access_endpoint("keystone-api", "keystone","service-api")
keystone = get_settings_by_role("keystone-setup", "keystone")
keystone_auth_url = "http://#{ks_admin_endpoint["host"]}:#{ks_service_endpoint["port"]}/v2.0/"

# Register Service Tenant
keystone_tenant "Create Service Tenant" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["swift"]["service_tenant_name"]
  tenant_description "Service Tenant"
  tenant_enabled true # Not required as this is the default
  action :create
end

# Register Service User
keystone_user "Create Service User" do
  auth_host ks_admin_endpoint["host"]
  auth_port ks_admin_endpoint["port"]
  auth_protocol ks_admin_endpoint["scheme"]
  api_ver ks_admin_endpoint["path"]
  auth_token keystone["admin_token"]
  tenant_name node["swift"]["service_tenant_name"]
  user_name node["swift"]["dispersion_service_user"]
  user_pass node["swift"]["dispersion_service_pass"]
  user_enabled true # Not required as this is the default
  action :create
end

 ## Grant Admin role to Service User for Service Tenant ##
  keystone_role "Grant 'admin' Role to Service User for Service Tenant" do
    auth_host ks_admin_endpoint["host"]
    auth_port ks_admin_endpoint["port"]
    auth_protocol ks_admin_endpoint["scheme"]
    api_ver ks_admin_endpoint["path"]
    auth_token keystone["admin_token"]
    tenant_name node["swift"]["service_tenant_name"]
    user_name node["swift"]["dispersion_service_user"]
    role_name node["swift"]["service_role"]
    action :grant
  end

# dispersion tools only work right now with swauth auth
execute "populate-dispersion" do
  command "swift-dispersion-populate"
  user "swift"
  action :nothing
  only_if "swift -V 2.0 -U #{node["swift"]["service_tenant_name"]}:#{node["swift"]["dispersion_service_user"]} -K '#{node["swift"]["dispersion_service_pass"]}' -A #{keystone_auth_url} stat dispersion_objects 2>&1 | grep 'Container.*not found'"
end

template "/etc/swift/dispersion.conf" do
  source "dispersion.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  variables("auth_url" => keystone_auth_url,
            "auth_user" => node["swift"]["dispersion_service_user"],
            "auth_tenant" => node["swift"]["service_tenant_name"],
            "auth_key" => node["swift"]["dispersion_service_pass"])
  only_if "swift-recon --objmd5 | grep -q '0 error'"
  notifies :run, "execute[populate-dispersion]", :immediately
end
