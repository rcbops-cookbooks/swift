# valid: :swauth or :keystone
default["swift"]["authmode"] = :swauth
default["swift"]["audit_hour"] = "5"
default["swift"]["disk_enum_expr"] = "node[:block_device]"

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

