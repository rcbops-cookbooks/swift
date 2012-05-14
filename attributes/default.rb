# valid: :swauth or :keystone
default["swift"]["authmode"] = "swauth"
default["swift"]["audit_hour"] = "5"
default["swift"]["disk_enum_expr"] = "node[:block_device]"
default["swift"]["auto_rebuild_rings"] = false

default["swift"]["service_tenant_name"] = "service"
default["swift"]["service_user"] = "swift"
default["swift"]["service_pass"] = "tYPvpd5F"
default["swift"]["service_role"] = "admin"

default["swift"]["api"]["bind_address"] = "0.0.0.0"
default["swift"]["api"]["port"] = "8080"
default["swift"]["api"]["ip_address"] = node["ipaddress"]
default["swift"]["api"]["protocol"] = "http"
default["swift"]["api"]["adminURL"] = "#{node["swift"]["api"]["protocol"]}://#{node["swift"]["api"]["ip_address"]}:#{node["swift"]["api"]["port"]}/v1/AUTH_%(tenant_id)s"
default["swift"]["api"]["internalURL"] = node["swift"]["api"]["adminURL"]
default["swift"]["api"]["publicURL"] = node["swift"]["api"]["adminURL"]

# disk_test_filter is an array of predicates to test against disks to
# determine if a disk should be formatted and configured for swift.
# Each predicate is evaluated in turn, and a false from the predicate
# will result in the disk not being considered as a candidate for
# formatting.
default["swift"]["disk_test_filter"] = [ "candidate =~ /sd[^a]/ or candidate =~ /hd[^a]/ or candidate =~ /vd[^a]/",
                                         "File.exist?('/dev/' + candidate)",
                                         "not system('/sbin/sfdisk -V /dev/' + candidate + '> /dev/null 2>&1')",
                                         "info['removable'] = 0"
                                       ]

# some attributes to control where network interfaces are laid down

# where LB public interfaces get dropped.  Or should these get mapped by convention?
default["osops_networks"]["mapping"]["swift-lb"] = "public"
default["osops_networks"]["mapping"]["swift-private"] = "swift"
default["osops_networks"]["mapping"]["swift-public"] = "public"

# Attributes for differences between distros.
default["swift"]["attributes"] = {
  "ubuntu" => {
    "service_prefix" => "",
    "service_suffix" => "",
    "package_override_options" => "-o Dpkg::Options:='--force-confold' -o Dpkg::Options:='--force-confdef'",
    "service_provider_class" => "Chef::Provider::Service::Upstart",
    "packages" => {
      "account" => "swift-account"
    }
  },
  "fedora" => {
    "service_prefix" => "openstack-",
    "service_suffix" => ".service",
    "package_override_options" => "",
    "service_provider_class" => "Chef::Provider::Service::Systemd",
    "packages" => {
      "account" => "openstack-swift-account"
    }
  },
  "fedora-17" => {
  }
}

