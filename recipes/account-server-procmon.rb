#
# Cookbook Name:: swift
# Recipe:: account-server-procmon
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

platform_options = node["swift"]["platform"]

if node["enable_monit"] and
    File.exists?("/etc/swift/account-server.conf") and
    File.exists?("/etc/swift/account.ring.gz")

  include_recipe "monit::server"

  %w{swift-account swift-account-auditor swift-account-reaper swift-account-replicator}.each do |svc|
    monit_procmon svc do
      process_name "python.*#{svc}.*"
      start_cmd "/usr/sbin/service " + svc + " start"
      stop_cmd "/usr/sbin/service " + svc + " stop"
    end
  end
end
