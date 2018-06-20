#!/usr/bin/env bash
# Simple prep scripts for rchain. Use Docker, LXD or some other container software to start up Ubuntu 18.04 host
#
# Get started by running a container that has access to your host docker.sock so we can do "nested docker"
# sudo docker run -dit -v /var/run/docker.sock:/var/run/docker.sock --name rchaindevhost ubuntu:bionic
# sudo docker exec -it rchaindevhost /bin/bash

# Prep "set" for CI if CI environment variable is set
if [[ "${CI}" = "true" ]]; then
set -exo pipefail
else
set -eo pipefail
fi

### Install all dependencies on Ubuntu 16.04 LTS (Xenial Xerus) for RChain dev environment.

## Verify operating system (OS) version is Ubuntu 16.04 LTS (Xenial Xerus)
# Add more OS versions as necessary. 
version=$(cat /etc/*release | grep "^VERSION_ID" | awk -F= '{print $2}' | sed 's/"//g')
if [[ "$version" == "18.04" ]]; then
echo "Running install on Ubuntu 18.04" 
else
echo "Error: Not running on Ubuntu 18.04"
echo "Exiting"
exit
fi

## Install Docker-CE
apt-get update -yqq
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu xenial stable"
apt-get update -yqq
apt install -y docker-ce sudo wget curl
apt install -y python3 python3-pip

## Resynchronize the package index files from their sources
apt-get update -yqq
## Install g++ multilib for cross-compiling as rosette is currently only 32-bit
apt-get install g++-multilib -yqq
## Install misc tools 
apt-get install cmake curl git -yqq
## Install Java OpenJDK 8
# apt-get install default-jdk -yqq # alternate jdk install 
apt-get install openjdk-8-jdk -yqq

## Python 3.6 Install
# python_version='3.6.5'
# apt-get -y update
# apt-get -y upgrade
# apt-get -y install libssl-dev zlib1g-dev gcc make libopal-dev 
# wget https://www.python.org/ftp/python/$python_version/Python-$python_version.tgz
# tar xzf Python-$python_version.tgz
# cd Python-$python_version
# ./configure --prefix=/usr/local
# make altinstall

## Install Haskell Platform for bnfc
# ref: https://www.haskell.org/platform/#linux-ubuntu
# ref: https://www.haskell.org/platform/ # all platforms
apt-get install haskell-platform -yqq

## Install SBT 
apt-get install apt-transport-https -yqq
echo "deb https://dl.bintray.com/sbt/debian /" | tee -a /etc/apt/sources.list.d/sbt.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
apt-get update -yqq
apt-get install sbt -yqq

## Install JFlex 
apt-get install jflex -yqq

## Install packages for additional builds
apt-get install autoconf libtool -yqq

#./scripts/install_secp.sh
apt-get -yq install libsecp256k1-0
#./scripts/install_sodium.sh
apt-get -yq install libsodium23
# apt-get -yq install bnfc # 2.8.1 is last release and doesn't have Kyle's changes

apt-get -yq install rpm
apt-get -yq install fakeroot
# apt-get -yq install libprotobuf-dev - not used yet nixos does this

# add rosette debian package
protobuf_build_dir=$(mktemp -d /tmp/protobuf_build.XXXXXXXX)
cd ${protobuf_build_dir}

wget https://github.com/google/protobuf/releases/download/v3.5.1/protobuf-cpp-3.5.1.tar.gz
tar -xzf protobuf-cpp-3.5.1.tar.gz
cd protobuf-3.5.1
./configure --build=i686-pc-linux-gnu CFLAGS="-m32 -DNDEBUG" CXXFLAGS="-m32 -DNDEBUG" LDFLAGS=-m32
make
make check
sudo make install
sudo ldconfig # refresh shared library cache.

rchain_build_dir=$(mktemp -d /tmp/rchain_build.XXXXXXXX)
cd ${rchain_build_dir}
# get the src code
git clone https://github.com/rchain/rchain

# compile rosette if wanted 
cd rchain/rosette
./build.sh
apt -y install ./build.out/rosette-*.deb

python3.6 -m pip install docker argparse pexpect requests

cd ..
./scripts/install_bnfc.sh

# Create docker image - requires running and accessible docker
sudo sbt -Dsbt.log.noformat=true clean rholang/bnfc:generate node/docker:publishLocal

# Create packages
sudo sbt -Dsbt.log.noformat=true clean rholang/bnfc:generate node/rpm:packageBin node/debian:packageBin node/universal:packageZipTarball

artifacts_dir=$(mktemp -d /tmp/artifacts_out.XXXXXXXX)
cp node/target/rnode_*_all.deb ${artifacts_dir}/rnode.deb
cp node/target/rpm/RPMS/noarch/rnode-*.noarch.rpm ${artifacts_dir}/rnode.rpm
cp rosette/build.out/rosette-*.deb ${artifacts_dir}/rosette.deb

echo "=========================================================="
echo "To collect built artifacts and copy somewhere"
echo "cd ${artifacts_dir}"
echo "scp somewhere"
echo "=========================================================="
echo "Or push docker by finding image"
echo "docker images | grep rnode"
echo "doocker tag and then docker push"
echo "=========================================================="
echo "Building artifacts from rchain build dir after making changes"
echo "To go to rchain build directory and make some modifications and produce new artifacts"
echo "cd ${rchain_build_dir}/rchain"
echo "make your changes"
echo "sudo sbt -Dsbt.log.noformat=true clean rholang/bnfc:generate node/docker:publishLocal"
echo "sudo sbt -Dsbt.log.noformat=true clean rholang/bnfc:generate node/rpm:packageBin node/debian:packageBin node/universal:packageZipTarbal"
echo "=========================================================="

## Clean Up
/bin/rm -rf ${protobuf_build_dir} # remove this as we don't need it anymore
# /bin/rm -rf ${rchain_build_dir} # uncomment if you want to delete rchain build directory
# /bin/rm -rf ${artifacts_dir} # uncomment if you want to delete artifacts store directory
