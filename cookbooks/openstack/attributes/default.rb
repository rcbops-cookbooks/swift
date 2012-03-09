# valid: :swauth or :keystone
default[:swift][:authmode] = :swauth

# this is gonna be set in shep's recipes
default[:controller_ipaddress] = node[:ipaddress]
