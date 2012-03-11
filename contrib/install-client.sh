#!/bin/bash

# could be overridden externally to provide a -o User or -i option, for example
SSH_OPTS=${SSH_OPTS:-"-o UserKnownHostsFile=/dev/null -o User=${USER}"}
HOST=${1}
SERVER_FQDN=${2}

if [ -z "${HOST}" ] || [ -z "${SERVER_FQDN}" ]; then
    echo "Usage: ${0} <host> <server fqdn>"
    exit 1
fi

if ( grep -q "URL_TO_CHEF_SERVER" client.rb ); then
    echo "put in a proper url to your chef server."
    exit 1
fi

if [ ! -e validation.pem ]; then
    echo "Copy your validation pem from /etc/chef/whatever into this directory"
    exit 1
fi

tmpdir=$(mktemp -d)

cp validation.pem ${tmpdir}
cp client.rb ${tmpdir}

cat > ${tmpdir}/install.sh <<EOF
#!/bin/bash

if ( ! gpg --list-keys --secret-keyring /etc/apt/secring.gpg --trustdb-name /etc/apt/trustdb.gpg --keyring /etc/apt/trusted.gpg | grep 83EF826A ); then
    apt-key adv --keyserver keys.gnupg.net --recv-keys 83EF826A
fi

cat > /etc/apt/sources.list.d/opscode.list <<EOF2
deb http://apt.opscode.com/ $(lsb_release -cs)-0.10 main
EOF2

sudo apt-get install -y --force-yes debconf-utils
sudo mkdir -p /etc/chef
echo \"chef chef/chef_server_url string http://${SERVER_FQDN}:4000\" | sudo debconf-set-selections
sudo apt-get update
sudo apt-get install -y --force-yes chef
sudo /etc/init.d/chef-client stop
sudo cp /tmp/chef/* /etc/chef
sudo chef-client
EOF


ssh ${SSH_OPTS} ${HOST} -- mkdir -p /tmp/chef
scp ${SSH_OPTS} ${tmpdir}/* ${HOST}:/tmp/chef
ssh ${SSH_OPTS} ${HOST} -- sudo /bin/bash /tmp/chef/install.sh


