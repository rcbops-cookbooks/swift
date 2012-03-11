name "all-in-one"
description "combined storage and proxy server"
run_list "role[proxy-server]","role[object-server]","role[container-server]","role[account-server]"


