#! /bin/bash

set -e
set -u

function get_sel() {
    # $1 - debconf selection to get

    local value=""
    if ( debconf-get-selections | grep -q ${1}); then
	value=$(debconf-get-selections | grep ${1} | awk '{ print $4 }')
	echo "Found existing debconf value for ${1}: ${value}" >&2
    fi

    echo ${value}
}

locale-gen en_US.UTF-8

apt-get install -y --force-yes debconf-utils pwgen wget lsb-release

CHEF_URL=$(get_sel "chef/chef_server_url")
AMQP_PASSWORD=$(get_sel "chef-solr/amqp_password")
WEBUI_PASSWORD=$(get_sel "chef-server-webui/admin_password")

# defaults if not set
CHEF_URL=${CHEF_URL:-http://$(hostname -f):4000}
AMQP_PASSWORD=${AMQP_PASSWORD:-$(pwgen -1)}
WEBUI_PASSWORD=${WEBUI_PASSWORD:-$(pwgen -1)}

if ( ! gpg --list-keys --secret-keyring /etc/apt/secring.gpg --trustdb-name /etc/apt/trustdb.gpg --keyring /etc/apt/trusted.gpg | grep 83EF826A ); then
    apt-key adv --keyserver keys.gnupg.net --recv-keys 83EF826A
fi

cat > /etc/apt/sources.list.d/opscode.list <<EOF
deb http://apt.opscode.com/ $(lsb_release -cs)-0.10 main
EOF

cat <<EOF | debconf-set-selections
chef chef/chef_server_url string ${CHEF_URL}
chef-solr chef-solr/amqp_password password ${AMQP_PASSWORD}
chef-server-webui chef-server-webui/admin_password password ${WEBUI_PASSWORD}
EOF

apt-get update
apt-get install -y --force-yes opscode-keyring
sudo apt-get upgrade -y --force-yes
sudo apt-get install -y --force-yes chef chef-server

if [ -z ${SUDO_USER} ]; then
    SUDO_USER=root
fi

HOMEDIR=$(getent passwd ${SUDO_USER} | cut -d: -f6)
mkdir -p ${HOMEDIR}/.chef
cp /etc/chef/validation.pem /etc/chef/webui.pem ${HOMEDIR}/.chef
chown -R ${SUDO_USER}: ${HOMEDIR}/.chef

cat <<EOF | knife configure -i
${HOMEDIR}/.chef/knife.rb
${CHEF_URL}
chefadmin
chef-webui
${HOMEDIR}/.chef/webui.pem
chef-validator
${HOMEDIR}/.chef/validation.pem

EOF



