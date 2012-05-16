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
include_recipe "swift::proxy-server"

# FIXME: This should probably be a role (ring-builder?), so you don't end up
# with multiple repos!
include_recipe "swift::ring-repo"

if platform?(%w{fedora})
  # fedora, maybe other rhel-ish dists
  swift_swauth_package = "openstack-swauth"
else
  # debian, ubuntu, other debian-ish
  swift_swauth_package = "swauth"
end


package swift_swauth_package do
  action :upgrade
  only_if { node["swift"]["authmode"] == "swauth" }
end

# dsh_group "swift-storage" do
#   admin_user "root"
#   network "swift"
# end
