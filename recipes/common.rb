#
# Cookbook Name:: swift
# Recipe:: swift-common
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
include_recipe "osops-utils"

# force base package install to get groups
if platform?(%w{fedora})
  # fedora, maybe other rhel-ish dists
  swift_package = "openstack-swift"
else
  # debian, ubuntu, other debian-ish
  swift_package = "swift"
end

package swift_package do
  action :upgrade
end

directory "/etc/swift" do
  action :create
  owner "swift"
  group "swift"
  mode "0700"
  only_if "/usr/bin/id swift"
end

file "/etc/swift/swift.conf" do
  action :create
  owner "swift"
  group "swift"
  mode "0700"
  content "[swift-hash]\nswift_hash_path_suffix=#{node['swift']['swift_hash']}\n"
  only_if "/usr/bin/id swift"
end

# need a shell to dsh, among other things
user "swift" do
  shell "/bin/bash"
  action :modify
  only_if "/usr/bin/id swift"
end

package "git" do
  action :upgrade
end

# drop a ring puller script so we can dsh ring pulls
template "/etc/swift/pull-rings.sh" do
  source "pull-rings.sh.erb"
  owner "swift"
  group "swift"
  mode "0700"
  variables({
              :builder_ip => IPManagement.get_ips_for_role("swift-management-server","swift",node)[0]
            })
  only_if "/usr/bin/id swift"
end

execute "/etc/swift/pull-rings.sh" do
  cwd "/etc/swift"
  only_if "[ -x /etc/swift/pull-rings.sh ]"
end


