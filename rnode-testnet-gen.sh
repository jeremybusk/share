#!/usr/bin/env bash

if [[ $1 && $2 ]]; then
    echo "Running custom build"
    branch_name=$2
    git_repo=$1
else
    echo "Invalid number of parameters."
    echo "Usage: $0 <repo url>> <branch name>"
    echo "Usage: $0 https://github.com/rchain/rchain dev"
    exit
fi

sudo echo ""
git_dir=$(mktemp -d /tmp/rchain-git.XXXXXXXX)
cd ${git_dir}
git clone ${git_repo} 
cd rchain
git checkout ${branch_name}
sbt -Dsbt.log.noformat=true clean rholang/bnfc:generate node/debian:packageBin

NETWORK_UID="1"
network_name="${NETWORK_UID}.rnode.test.net"

# Create network if it doesn't exist
sudo docker network create \
  --driver=bridge \
  --subnet=10.1.1.0/24 \
  --ip-range=10.1.1.0/24 \
  --gateway=10.1.1.1 \
  ${network_name}

for i in {0..3}; do
    container_name="node${i}.${network_name}"
    echo $container_name

	# If container exists force remove it.
	if [[ $(sudo docker ps -aq -f name=${container_name}) ]]; then
		sudo docker rm -f ${container_name}
	fi

	sudo docker run -dit --name ${container_name} \
        -v $git_dir/rchain/node/target/rnode_0.2.1_all.deb:/rnode_0.2.1_all.deb \
        --network=${network_name} \
        openjdk

    if [[ $i == 0 ]]; then
        rnode_cmd="rnode --port 30304 --standalone --name 0f365f1016a54747b384b386b8e85352 > /var/log/rnode.log 2>&1 &"
    else
        rnode_cmd="rnode --bootstrap rnode://0f365f1016a54747b384b386b8e85352@10.1.1.2:30304 > /var/log/rnode.log 2>&1 &"
    fi

    branch_name="0.2.1"
	sudo docker exec ${container_name} bash -c "apt -y update; apt -y iputils-ping bridge-utils iproute2; apt -y install ./rnode_${branch_name}_all.deb; mkdir /var/lib/rnode; ${rnode_cmd}" 

done
sudo docker exec node0.1.rnode.test.net bash -c "cat /var/log/rnode.log"

echo "Run below to go into standaloner server"
echo "sudo docker exec -it node0.1.rnode.test.net /bin/bash"
#sudo docker exec ${container_name} bash -c "cat /var/log/rnode.log"
