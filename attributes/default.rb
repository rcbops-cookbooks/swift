# valid: :swauth or :keystone
default["swift"]["authmode"] = "swauth"
default["swift"]["audit_hour"] = "5"
default["swift"]["disk_enum_expr"] = "node[:block_device]"

default["swift"]["service_tenant_name"] = "service"
default["swift"]["service_user"] = "swift"
default["swift"]["service_pass"] = "tYPvpd5F"
default["swift"]["service_role"] = "admin"

default["swift"]["api"]["bind_address"] = "0.0.0.0"
default["swift"]["api"]["port"] = "80"
default["swift"]["api"]["ip_address"] = node["ipaddress"]
default["swift"]["api"]["protocol"] = "http"
default["swift"]["api"]["adminURL"] = "#{node["swift"]["api"]["protocol"]}://#{node["swift"]["api"]["ip_address"]}:#{node["swift"]["api"]["port"]}"
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

# If set, this identifies an operator expected list of drives to use.
# If the system has fewer (or other) drives than this, processing will
# fail.  This is a way to ensure that random, undesired drives don't get
# picked up.  Really just a safety net.

# default["swift"]["expected_disks"] = '("b".."f").collect{|x| "sd#{x}"}'

# some attributes to control where network interfaces are laid down

# where LB public interfaces get dropped.  Or should these get mapped by convention?
default["osops_networks"]["mapping"]["swift-lb"] = "public"
default["osops_networks"]["mapping"]["swift-private"] = "swift"
default["osops_networks"]["mapping"]["swift-public"] = "public"

