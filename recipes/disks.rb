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
# Author: Ron Pedde <ron.pedde@rackspace.com>
# Inspired by: Andi Abes @ Dell

include_recipe "osops-utils"

class Chef::Recipe
  include DriveUtils
end

include_recipe "osops-utils"

%w(xfsprogs parted util-linux).each do |pkg|
  package pkg do
    action :upgrade
  end
end

disks = locate_disks(node["swift"]["disk_enum_expr"],
                     node["swift"]["disk_test_filter"])

disks.each do |disk|
  swift_disk "/dev/#{disk}" do
    part [{:type => "xfs", :size => :remaining}]
    action :ensure_exists
  end
end

swift_mounts "/srv/node" do
  action :ensure_exists
  publish_attributes "swift/state/devs"
  devices disks.collect { |x| "#{x}1" }
  ip IPManagement.get_ip_for_net("swift-public", node)
end

