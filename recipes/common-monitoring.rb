#
# Cookbook Name:: swift
# Recipe:: common-monitoring
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
include_recipe "collectd-graphite::collectd-client"

# This should be in the base collectd package...
package "libpython2.7" do
  action :install
end

cookbook_file File.join(node["collectd"]["plugin_dir"], "swift_stats.py") do
  source "swift_stats.py"
  owner "root"
  group "root"
  mode "0644"

  notifies :restart, resources(:service => "collectd"), :delayed
end

collectd_python_plugin "swift_stats"
