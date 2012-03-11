name "account-server"
description "swift account server"
run_list {
  "recipe[openstack::swift-account-server]"
}

