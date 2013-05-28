#
# Cookbook Name:: nova
# Recipe:: swift-dispersion-patch
#
# Copyright 2009, Rackspace Hosting, Inc.
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

include_recipe "osops-utils"

template "/usr/bin/swift-dispersion-populate" do
  source "patches/swift-dispersion-populate.1.4.8-0ubuntu2.erb"
  owner "root"
  group "root"
  mode "0755"
  only_if { ::Chef::Recipe::Patch.check_package_version("swift","1.4.8-0ubuntu2",node) }
end

template "/usr/bin/swift-dispersion-report" do
  source "patches/swift-dispersion-report.1.4.8-0ubuntu2.erb"
  owner "root"
  group "root"
  mode "0755"
  only_if { ::Chef::Recipe::Patch.check_package_version("swift","1.4.8-0ubuntu2",node) }
end
