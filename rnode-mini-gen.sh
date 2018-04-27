#!/usr/bin/env bash

# create network
#docker network create --driver bridge birch-net
git_repo="https://github.com/KentShikama/rchain"
branch_name="dev-kent-minimum-block-passing"
working_dir=$(pwd)
git_dir=$(mktemp -d /tmp/rchain-git.XXXXXXXX)
cd ${git_dir}
git clone ${git_repo} 
cd rchain
git checkout ${branch_name}
sbt -Dsbt.log.noformat=true clean rholang/bnfc:generate node/debian:packageBin
cd ${working_dir}
#$git_dir/rchain/node/target/rnode_0.2.1_all.deb
# branch=

NETWORK_UID="1"
network_name="${NETWORK_UID}.rnode.test.net"

sudo docker network create \
  --driver=bridge \
  --subnet=10.1.1.0/24 \
  --ip-range=10.1.1.0/24 \
  --gateway=10.1.1.1 \
  ${network_name}

for i in {0..3}; do
    container_name="node${i}.${network_name}"
    echo $container_name
    public_ssh_port=$(($SSH_PORT_START + $i))
    echo $public_ssh_port

	# If container exists force remove it.
	if [[ $(sudo docker ps -aq -f name=${container_name}) ]]; then
		sudo docker rm -f ${container_name}
	fi

	#docker run -dit --name ${container_name} --network=${network_name} -p ${public_ssh_port}:22 openjdk
        #--volume rchain/node/target/rnode_0.2.1_all.deb:/rnode_0.2.1_all.deb \
	sudo docker run -dit --name ${container_name} \
        -v $git_dir/rchain/node/target/rnode_0.2.1_all.deb:/rnode_0.2.1_all.deb \
        --network=${network_name} \
        openjdk
    if [[ $i == 0 ]]; then
        rnode_cmd="rnode --port 30304 --standalone --name 0f365f1016a54747b384b386b8e85352 > /var/log/rnode.log 2>&1 &"
    else
        rnode_cmd="rnode --bootstrap rnode://0f365f1016a54747b384b386b8e85352@10.1.1.2:30304 > /var/log/rnode.log 2>&1 &"
    fi
    branch_name="dev"
    sudo docker exec ${container_name} bash -c "apt -y update; apt -y iputils-ping bridge-utils iproute2 install wget openssh-server; wget http://repo.pyr8.io:10002/rnode_${branch_name}_all.deb; apt -y install ./rnode_${branch_name}_all.deb; mkdir /var/lib/rnode; mkdir /root/.ssh; echo ${authorized_public_keys} >> /root/.ssh/authorized_keys; mkdir /var/run/sshd; service ssh start; apt -y remove --purge rnode; apt -y install rnode_0.2.1_all.deb; ${rnode_cmd}" 
done
