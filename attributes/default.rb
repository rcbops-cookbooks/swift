# blank initial swift state
default["swift"]["state"] = {}
# valid: :swauth or :keystone
default["swift"]["authmode"] = "swauth"
default["swift"]["audit_hour"] = "5"
default["swift"]["disk_enum_expr"] = "node[:block_device]"
default["swift"]["auto_rebuild_rings"] = false

default["swift"]["service_tenant_name"] = "service"
default["swift"]["service_user"] = "swift"
default["swift"]["dispersion_service_user"] = "dispersion"
# Replacing with OpenSSL::Password in recipes/proxy-server.rb
#default["swift"]["service_pass"] = "tYPvpd5F"
default["swift"]["service_role"] = "admin"

# should we use swift-informant?
# we'll default this to off until we get upstream
# packages from distros.  You can still use it, just be aware
# it gets packages from the osops ppa
default["swift"]["use_informant"] = false

default["swift"]["services"]["proxy"]["scheme"] = "http"
default["swift"]["services"]["proxy"]["network"] = "swift-public"
default["swift"]["services"]["proxy"]["port"] = 8080
default["swift"]["services"]["proxy"]["path"] = "/v1"

default["swift"]["services"]["object-server"]["network"] = "swift"
default["swift"]["services"]["object-server"]["port"] = 6000

default["swift"]["services"]["container-server"]["network"] = "swift"
default["swift"]["services"]["container-server"]["port"] = 6001

default["swift"]["services"]["account-server"]["network"] = "swift"
default["swift"]["services"]["account-server"]["port"] = 6002

default["swift"]["services"]["memcache"]["network"] = "swift"
default["swift"]["services"]["memcache"]["port"] = 11211

default["swift"]["services"]["ring-repo"]["network"] = "swift"
default["swift"]["services"]["ring-repo"]["port"] = 9418
default["swift"]["services"]["ring-repo"]["scheme"] = "git"
default["swift"]["services"]["ring-repo"]["path"] = "/rings"

# disk_test_filter is an array of predicates to test against disks to
# determine if a disk should be formatted and configured for swift.
# Each predicate is evaluated in turn, and a false from the predicate
# will result in the disk not being considered as a candidate for
# formatting.
default["swift"]["disk_test_filter"] = [ "candidate =~ /sd[^a]/ or candidate =~ /hd[^a]/ or candidate =~ /vd[^a]/",
                                         "File.exist?('/dev/' + candidate)",
                                         "info['removable'] = 0"
                                       ]

# some attributes to control where network interfaces are laid down

# where LB public interfaces get dropped.  Or should these get mapped by convention?
default["osops_networks"]["mapping"]["swift-lb"] = "public"
default["osops_networks"]["mapping"]["swift-private"] = "swift"
default["osops_networks"]["mapping"]["swift-public"] = "public"


# attributes for monitoring

# disk space percentage used before warning/error
default["swift"]["monitoring"]["used_warning"] = 80
default["swift"]["monitoring"]["used_failure"] = 85

# other (non-swift) disk space before warning/error
default["swift"]["monitoring"]["other_warning"] = 80
default["swift"]["monitoring"]["other_failure"] = 95


# Leveling between distros
case platform
when "fedora"
  default["swift"]["platform"] = {
    "proxy_packages" => ["openstack-swift-proxy"],
    "object_packages" => ["openstack-swift-object"],
    "container_packages" => ["openstack-swift-container"],
    "account_packages" => ["openstack-swift-account"],
    "swift_packages" => ["openstack-swift"],
    "swauth_packages" => ["openstack-swauth"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["git", "git-daemon"],
    "memcached_config_file" => "/etc/sysconfig/memcached",
    "service_prefix" => "openstack-",
    "service_suffix" => ".service",
    "git_dir" => "/var/lib/git",
    "git_service" => "git",
    "service_provider" => Chef::Provider::Service::Systemd,
    "override_options" => ""
  }
when "ubuntu"
  default["swift"]["platform"] = {
    "proxy_packages" => ["swift-proxy"],
    "object_packages" => ["swift-object"],
    "container_packages" => ["swift-container"],
    "account_packages" => ["swift-account", "python-swiftclient"],
    "swift_packages" => ["swift"],
    "swauth_packages" => ["swauth"],
    "rsync_packages" => ["rsync"],
    "git_packages" => ["git-daemon-sysvinit"],
    "memcached_config_file" => "/etc/memcached.conf",
    "service_prefix" => "",
    "service_suffix" => "",
    "git_dir" => "/var/cache/git",
    "git_service" => "git-daemon",
    "service_provider" => Chef::Provider::Service::Upstart,
    "override_options" => "-o Dpkg::Options:='--force-confold' -o Dpkg::Option:='--force-confdef'"
  }
end
