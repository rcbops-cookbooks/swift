#
# Cookbook Name:: swift
# Recipe:: ring-repo
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

# This recipe creates a git ring repository on the management node
# for purposes of ring synchronization
#

%w(git git-daemon-sysvinit).each do |pkg|
  package pkg do
    action :upgrade
  end
end

execute "create empty git repo" do
  cwd "/tmp"
  umask 022
  command "mkdir $$; cd $$; git init; echo \"*~\" \> .gitignore; git add .gitignore; git commit -m 'initial commit' --author='chef <chef@openstack>'; git push file:///var/cache/git/rings master"
  action :nothing
end

execute "initialize git repo" do
  cwd "/var/cache/git/rings"
  umask 022
  command "git init --bare && touch git-daemon-export-ok"
  creates "/var/cache/git/rings/.git"
  action :nothing
  notifies :run, resources(:execute => "create empty git repo"), :immediately
end

directory "/var/cache/git/rings" do
  owner "root"
  group "root"
  mode "0755"
  action :create
  notifies :run, resources(:execute => "initialize git repo"), :immediately
end

service "git-daemon" do
  action [ :enable, :start ]
end

cookbook_file "/etc/default/git-daemon" do
  owner "root"
  group "root"
  mode "644"
  source "git-daemon.default"
  action :create
  notifies :restart, resources(:service => "git-daemon"), :immediately
end


