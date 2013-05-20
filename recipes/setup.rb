#
# Cookbook Name:: swift
# Recipe:: setup
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

::Chef::Recipe.send(:include, Opscode::OpenSSL::Password)
include_recipe "swift::common"
include_recipe "osops-utils"

# make sure we die if there are multiple swift-setups
if get_role_count("swift-setup", false) > 0
  Chef::Application.fatal! "You can only have one node with the swift-setup role"
end

unless node["swift"]["service_pass"]
  Chef::Log.info("Running swift setup - setting swift passwords")
end

# Set a secure keystone service password
node.set_unless['swift']['service_pass'] = secure_password

platform_options = node["swift"]["platform"]

# install platform-specific packages
platform_options["proxy_packages"].each do |pkg|
  package pkg do
    action :upgrade
    options platform_options["override_options"]
  end
end

package "python-swauth" do
  action :upgrade
  only_if { node["swift"]["authmode"] == "swauth" }
end

package "python-swift-informant" do
  action :upgrade
  only_if { node["swift"]["use_informant"] }
end

package "python-keystone" do
  action :upgrade
  only_if { node["swift"]["authmode"] == "keystone" }
end

# register with keystone
if node["swift"]["authmode"] == "keystone"

  keystone = get_settings_by_role("keystone-setup", "keystone")
  ks_admin = get_access_endpoint("keystone-api","keystone","admin-api")
  ks_service = get_access_endpoint("keystone-api","keystone","service-api")
  proxy_access = get_access_endpoint("swift-proxy-server","swift", "proxy")

  # Register Service Tenant
  keystone_tenant "Create Service Tenant" do
    auth_host ks_admin["host"]
    auth_port ks_admin["port"]
    auth_protocol ks_admin["scheme"]
    api_ver ks_admin["path"]
    auth_token keystone["admin_token"]
    tenant_name node["swift"]["service_tenant_name"]
    tenant_description "Service Tenant"
    tenant_enabled true # Not required as this is the default
    action :create
  end

  # Register Service User
  keystone_user "Create Service User" do
    auth_host ks_admin["host"]
    auth_port ks_admin["port"]
    auth_protocol ks_admin["scheme"]
    api_ver ks_admin["path"]
    auth_token keystone["admin_token"]
    tenant_name node["swift"]["service_tenant_name"]
    user_name node["swift"]["service_user"]
    user_pass node["swift"]["service_pass"]
    user_enabled true # Not required as this is the default
    action :create
  end

  ## Grant Admin role to Service User for Service Tenant ##
  keystone_role "Grant 'admin' Role to Service User for Service Tenant" do
    auth_host ks_admin["host"]
    auth_port ks_admin["port"]
    auth_protocol ks_admin["scheme"]
    api_ver ks_admin["path"]
    auth_token keystone["admin_token"]
    tenant_name node["swift"]["service_tenant_name"]
    user_name node["swift"]["service_user"]
    role_name node["swift"]["service_role"]
    action :grant
  end

  # Register Storage Service
  keystone_service "Create Storage Service" do
    auth_host ks_admin["host"]
    auth_port ks_admin["port"]
    auth_protocol ks_admin["scheme"]
    api_ver ks_admin["path"]
    auth_token keystone["admin_token"]
    service_name "swift"
    service_type "object-store"
    service_description "Swift Object Storage Service"
    action :create
  end

  # Register Storage Endpoint
  keystone_endpoint "Register Storage Endpoint" do
    auth_host ks_admin["host"]
    auth_port ks_admin["port"]
    auth_protocol ks_admin["scheme"]
    api_ver ks_admin["path"]
    auth_token keystone["admin_token"]
    service_type "object-store"
    endpoint_region "RegionOne"
    endpoint_adminurl proxy_access['uri']
    endpoint_internalurl proxy_access['uri']
    endpoint_publicurl proxy_access['uri']
    action :create
  end
end
