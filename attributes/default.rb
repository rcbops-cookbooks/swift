# blank initial swift state
default["swift"]["state"] = {}
# valid: :swauth or :keystone
default["swift"]["authmode"] = "swauth"                                     # cluster_attribute
default["swift"]["audit_hour"] = "5"                                        # cluster_attribute
default["swift"]["disk_enum_expr"] = "node[:block_device]"                  # cluster_attribute
default["swift"]["auto_rebuild_rings"] = false                              # cluster_attribute
default["swift"]["autozone"] = false                                        # cluster_attribute

default["swift"]["service_tenant_name"] = "service"                         # node_attribute
default["swift"]["service_user"] = "swift"                                  # node_attribute
default["swift"]["dispersion_service_user"] = "dispersion"                  # node_attribute
# Replacing with OpenSSL::Password in recipes/proxy-server.rb
#default["swift"]["service_pass"] = "tYPvpd5F"
default["swift"]["service_role"] = "admin"                                  # node_attribute

# should we use swift-informant?
# we'll default this to off until we get upstream
# packages from distros.  You can still use it, just be aware
# it gets packages from the osops ppa
default["swift"]["use_informant"] = false                                   # cluster_attribute

default["swift"]["services"]["proxy"]["scheme"] = "http"                    # node_attribute
default["swift"]["services"]["proxy"]["network"] = "swift-public"           # node_attribute (inherited from cluster?)
default["swift"]["services"]["proxy"]["port"] = 8080                        # node_attribute (inherited from cluster?)
default["swift"]["services"]["proxy"]["path"] = "/v1/AUTH_%(tenant_id)s"                       # node_attribute

default["swift"]["services"]["object-server"]["network"] = "swift"          # node_attribute (inherited from cluster?)
default["swift"]["services"]["object-server"]["port"] = 6000                # node_attribute (inherited from cluster?)

default["swift"]["services"]["container-server"]["network"] = "swift"       # node_attribute (inherited from cluster?)
default["swift"]["services"]["container-server"]["port"] = 6001             # node_attribute (inherited from cluster?)

default["swift"]["services"]["account-server"]["network"] = "swift"         # node_attribute (inherited from cluster?)
default["swift"]["services"]["account-server"]["port"] = 6002               # node_attribute (inherited from cluster?)

default["swift"]["services"]["ring-repo"]["network"] = "swift"              # node_attribute (inherited from cluster?)
default["swift"]["services"]["ring-repo"]["port"] = 9418                    # node_attribute (inherited from cluster?)
default["swift"]["services"]["ring-repo"]["scheme"] = "git"                 # node_attribute
default["swift"]["services"]["ring-repo"]["path"] = "/rings"                # node_attribute

# disk_test_filter is an array of predicates to test against disks to
# determine if a disk should be formatted and configured for swift.
# Each predicate is evaluated in turn, and a false from the predicate
# will result in the disk not being considered as a candidate for
# formatting.
default["swift"]["disk_test_filter"] = [ "candidate =~ /sd[^a]/ or candidate =~ /hd[^a]/ or candidate =~ /vd[^a]/ or candidate =~ /xvd[^a]/",
                                         "File.exist?('/dev/' + candidate)",
                                         "not system('/sbin/parted /dev/' + candidate + ' -s print | grep linux-swap')",
                                         "info['removable'] == 0.to_s"
                                       ]                                    # cluster_attribute

# some attributes to control where network interfaces are laid down

# where LB public interfaces get dropped.  Or should these get mapped by convention?
default["osops_networks"]["mapping"]["swift-lb"] = "public"                 # cluster_attribute
default["osops_networks"]["mapping"]["swift-private"] = "swift"             # cluster_attribute
default["osops_networks"]["mapping"]["swift-public"] = "public"             # cluster_attribute


# attributes for monitoring

# disk space percentage used before warning/error
default["swift"]["monitoring"]["used_warning"] = 80                         # node_attribute (inherited from cluster?)
default["swift"]["monitoring"]["used_failure"] = 85                         # node_attribute (inherited from cluster?)

# other (non-swift) disk space before warning/error
default["swift"]["monitoring"]["other_warning"] = 80                        # node_attribute (inherited from cluster?)
default["swift"]["monitoring"]["other_failure"] = 95                        # node_attribute (inherited from cluster?)


# Leveling between distros
case platform
when "redhat"
  default["swift"]["platform"] = {                      # node_attribute
    "disk_format" => "ext4",
    "proxy_packages" => ["openstack-swift-proxy", "sudo", "cronie", "python-memcached"],
    "object_packages" => ["openstack-swift-object", "sudo", "cronie"],
    "container_packages" => ["openstack-swift-container", "sudo", "cronie"],
    "account_packages" => ["openstack-swift-account", "sudo", "cronie"],
    "swift_packages" => ["openstack-swift", "sudo", "cronie"],
    "swauth_packages" => ["openstack-swauth", "sudo", "cronie"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["xinetd", "git", "git-daemon"],
    "service_prefix" => "openstack-",
    "service_suffix" => "",
    "git_dir" => "/var/lib/git",
    "git_service" => "git",
    "service_provider" => Chef::Provider::Service::Redhat,
    "override_options" => ""
  }
#
# python-iso8601 is a missing dependency for swift.
# https://bugzilla.redhat.com/show_bug.cgi?id=875948
when "centos"
  default["swift"]["platform"] = {                      # node_attribute
    "disk_format" => "xfs",
    "proxy_packages" => ["openstack-swift-proxy", "sudo", "cronie", "python-iso8601", "python-memcached" ],
    "object_packages" => ["openstack-swift-object", "sudo", "cronie", "python-iso8601" ],
    "container_packages" => ["openstack-swift-container", "sudo", "cronie", "python-iso8601" ],
    "account_packages" => ["openstack-swift-account", "sudo", "cronie", "python-iso8601" ],
    "swift_packages" => ["openstack-swift", "sudo", "cronie", "python-iso8601" ],
    "swauth_packages" => ["openstack-swauth", "sudo", "cronie", "python-iso8601" ],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["xinetd", "git", "git-daemon"],
    "service_prefix" => "openstack-",
    "service_suffix" => "",
    "git_dir" => "/var/lib/git",
    "git_service" => "git",
    "service_provider" => Chef::Provider::Service::Redhat,
    "override_options" => ""
  }
when "fedora"
  default["swift"]["platform"] = {                                          # node_attribute
    "disk_format" => "xfs",
    "proxy_packages" => ["openstack-swift-proxy", "python-memcached"],
    "object_packages" => ["openstack-swift-object"],
    "container_packages" => ["openstack-swift-container"],
    "account_packages" => ["openstack-swift-account"],
    "swift_packages" => ["openstack-swift"],
    "swauth_packages" => ["openstack-swauth"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["git", "git-daemon"],
    "service_prefix" => "openstack-",
    "service_suffix" => ".service",
    "git_dir" => "/var/lib/git",
    "git_service" => "git",
    "service_provider" => Chef::Provider::Service::Systemd,
    "override_options" => ""
  }
when "ubuntu"
  default["swift"]["platform"] = {                                          # node_attribute
    "disk_format" => "xfs",
    "proxy_packages" => ["swift-proxy", "python-memcache"],
    "object_packages" => ["swift-object"],
    "container_packages" => ["swift-container"],
    "account_packages" => ["swift-account", "python-swiftclient"],
    "swift_packages" => ["swift"],
    "swauth_packages" => ["swauth"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["git-daemon-sysvinit"],
    "service_prefix" => "",
    "service_suffix" => "",
    "git_dir" => "/var/cache/git",
    "git_service" => "git-daemon",
    "service_provider" => Chef::Provider::Service::Upstart,
    "override_options" => "-o Dpkg::Options::='--force-confold' -o Dpkg::Options::='--force-confdef'"
  }
end
