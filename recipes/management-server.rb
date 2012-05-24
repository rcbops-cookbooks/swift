#
# Cookbook Name:: swift
# Recipe:: swift-management-server
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
#include_recipe "swift::proxy-server"  # this is really only necessary for swauth.

# FIXME: This should probably be a role (ring-builder?), so you don't end up
# with multiple repos!
include_recipe "swift::ring-repo"

platform_options = node["swift"]["platform"]

platform_options["swauth_packages"].each do |pkg|
  package pkg do
    action :upgrade
    only_if { node["swift"]["authmode"] == "swauth" }
  end
end

dsh_group "swift-storage" do
  admin_user "root"
  network "swift"
end

# dispersion tools only work right now with swauth auth
execute "populate-dispersion" do
  command "swift-dispersion-populate"
  user "swift"
  action :nothing
  only_if { node["swift"]["authmode"] == "swauth" }
end

keystone = {}
# FIXME: library this out
if node["swift"]["authmode"] == "keystone"
  result = node

  if not Chef::Config[:solo]
    (result,*_), _, _ = Chef::Search::Query.new.search(:node, "roles:keystone AND chef_environment:#{node.chef_environment}")
    result = node if (result == nil or result.length <= 0)
  end

  keystone = result["keystone"].inject({}){ |hsh, (k,v)| hsh.merge(k => v) }

  # FIXME: this should really return ip and port
  keystone["api_ipaddress"]=IPManagement.get_access_ip_for_role("keystone", "swift-lb", node)
  keystone["auth_url"] = "http://#{keystone['api_ipaddress']}:#{keystone['service_port']}/v2.0/"
end

# FIXME: broken for swauth
template "/etc/swift/dispersion.conf" do
  source "dispersion.conf.erb"
  owner "swift"
  group "swift"
  mode "0600"
  variables("auth_url" => keystone["auth_url"],
            "auth_user" => keystone["admin_user"],
            "auth_key" => keystone["users"][auth_user]["password"])

  only_if "swift-recon --objmd5 | grep -q '0 error'"
  notifies :run, "execute[populate-dispersion]", :immediately
end
