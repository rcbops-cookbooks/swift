Support
=======

Issues have been disabled for this repository.  
Any issues with this cookbook should be raised here:

[https://github.com/rcbops/chef-cookbooks/issues](https://github.com/rcbops/chef-cookbooks/issues)

Please title the issue as follows:

[swift]: \<short description of problem\>

In the issue description, please include a longer description of the issue, along with any relevant log/command/error output.  
If logfiles are extremely long, please place the relevant portion into the issue description, and link to a gist containing the entire logfile

Description
====

Installs packages and configuration for OpenStack Swift

Requirements
====

Client:
 * CentOS >= 6.3
 * Ubuntu >= 12.04

Chef:
 * 0.10.8

Other variants of Ubuntu and Fedora may work, something crazy like
Solaris probably will not.  YMMV, objects in mirror, etc.

Attributes
====

 * node[:swift][:authmode] - "swauth" or "keystone" (default "swauth")

 * node[:swift][:swift_hash] - swift_hash_path_suffix in /etc/swift/swift.conf

 * node[:swift][:audit_hour] - Hour to run swift_auditor on storage nodes (default 5)

 * node[:swift][:disk_enum_expr] - Eval-able expression that lists
   candidate disk nodes for disk probing.  The result shoule be a hash
   with keys being the device name (without the leading "/dev/") and a
   hash block of any extra info associated with the device.  For
   example: { "sdc" => { "model": "Hitachi 7K3000" }}.  Largely,
   though, if you are going to make a list of valid devices, you
   probably know all the valid devices, and don't need to pass any
   metadata about them, so { "sdc" => {}} is probably enough.  Example
   expression: Hash[('a'..'f').collect{|x| [ "sd{x}", {} ]}]

 * node[:swift][:disk_test_filter] - an array of expressions that must
   all be true in order a block deviced to be considered for
   formatting and inclusion in the cluster.  Each rule gets evaluated
   with "candidate" set to the device name (without the leading
   "/dev/") and info set to the node hash value.  Default rules:

    * "candidate =~ /sd[^a]/ or candidate =~ /hd[^a]/ or candidate =~
      /vd[^a]/"

    * "File.exists?('/dev/ + candidate)"

    * "not system('/sbin/sfdisk -V /dev/' + candidate + '>/dev/null 2>&2')"

    * "info['removable'] = 0" ])

 * node[:swift][:expected_disks] - an array of device names that the
   operator expecs to be identified by the previous two values.  This
   acts as a second-check on discovered disks.  If this array doesn't
   match the found disks, then chef processing will be stopped.
   Example: ("b".."f").collect{|x| "sd#{x}"}.  Default: none.

There are other attributes that must be set depending on authmode.
For "swauth", the following attributes are used:

 * node[:swift][:authkey] - swauth "swauthkey" if using swauth

For "keystone", the following attributes are used:

 * [:keystone][:admin_port]

 * [:keystone][:admin_token]

 * [:keystone][:admin_user]

In addition, there are some attributes used by osops-utils to find
interfaces on particular devices.

 * node[:osops_networks][:swift] - CIDR of the storage network (what
   address to bind storage nodes to, what ip address to use in rings,
   etc)

 * node[:osops_networks][:public] - CIDR of the network that
   that the proxy listens to, or the load balancer for proxies listens
   on

Deps
====

 * dsh
 * keystone
 * openssl
 * osops-utils
 * sysctl

Roles
====

 * swift-account-server - storage node for account data
 * swift-container-server - storage node for container data
 * swift-object-server - storage node for object server
 * swift-proxy-server - proxy for swift storge nodes
 * swift-management-server - basically serves two functions:
   * proxy node with account management enabled
   * ring repository and ring building workstation
   THERE CAN ONLY BE ONE HOST WITH THE MANAGMENET SERVER ROLE!
 * swift-all-in-one - role shortcut for all object classes and proxy
   on one machine.

In small environments, it is likely that all storage machines will
have all-in-one roles, with a load balancer ahead of it

In larger environments, where it is cost effective to split the proxy
and storage layer, storage nodes will carry
swift-{account,container,object}-server roles, and there will be
dedicated hosts with the swift-proxy-server role.

In really really huge environments, it's possible that the storage
node will be split into swift-{container,accout}-server nodes and
swift-object-server nodes.

Examples
====

Example environment:


    {
	"override_attributes": {
	    "swift": {
		"swift_hash": "107c0568ea84",
		"authmode": "swauth",
		"authkey": "3f281b71-ce89-4b27-a2ad-ad873d3f2760"
	    },
	    "osops_networks": {
		"swift": "192.168.122.0/24"
	    }
	},
	"cookbook_versions": {
	},
	"description": "",
	"default_attributes": {
	},
	"name": "swift",
	"chef_type": "environment",
	"json_class": "Chef::Environment"
    }

This sets up defaults for a swauth-based cluster with the storage
network on 192.168.122.0/24.

Run list for proxy server:

    "run_list": [
        "role[swift-proxy-server]"
    ]

Run list for combined object, container, and account server:

    "run_list": [
        "role[swift-object-server]",
        "role[swift-container-server]",
        "role[swift-account-server]"
    ]

In addition, there *must* be a node with the the
swift-managment-server role to act as the ring repository.
a

License and Author
====

Author:: Ron Pedde (<ron.pedde@rackspace.com>)  
Author:: Will Kelly (<will.kelly@rackspace.com>)  
Author:: Andy McCrae (<andrew.mccrae@rackspace.co.uk>)  

Copyright:: 2012, Rackspace US, Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

