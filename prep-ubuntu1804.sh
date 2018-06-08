#!/usr/bin/env bash
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
curl -fsSL https://download.docker.com/linux/ubuntu/gpg |  apt-key add -
add-apt-repository    "deb [arch=amd64] https://download.docker.com/linux/ubuntu    xenial    stable"
apt-get update -yqq
apt install -y docker-ce sudo
apt install -y python3 python3-pip 

## Resynchronize the package index files from their sources
apt-get update -yqq
## Install g++ multilib for cross-compiling as rosette is currently only 32-bit
apt-get install g++-multilib -yqq
## Install misc tools 
apt-get install cmake curl git -yqq
## Install Java OpenJDK 8
#  apt-get install default-jdk -yqq # alternate jdk install 
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
echo "deb https://dl.bintray.com/sbt/debian /" |  tee -a /etc/apt/sources.list.d/sbt.list
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2EE0EA64E40A89B84B2DF73499E82A75642AC823
apt-get update -yqq
apt-get install sbt -yqq

## Install JFlex 
apt-get install jflex -yqq

## Install packages for additional builds
apt-get install autoconf libtool -yqq

python3.6 -m pip install docker argparse pexpect requests
git clone https://github.com/rchain/rchain
cd rchain
#./scripts/install_secp.sh
apt-get -yq install libsecp256k1-0
#./scripts/install_sodium.sh
apt-get -yq install libsodium23
./scripts/install_bnfc.sh
# apt-get -yq install bnfc # 2.8.1 is last release and doesn't have Kyle's changes

apt-get -yq install rpm
apt-get -yq install fakeroot
# apt-get -yq install libprotobuf-dev - not used yet nixos does this

# add rosette debian package
rosette_install_dir=$(mktemp -d /tmp/rosette_stage.XXXXXXXX)
cd ${rosette_install_dir}

wget https://github.com/google/protobuf/releases/download/v3.5.1/protobuf-cpp-3.5.1.tar.gz
tar -xzf protobuf-cpp-3.5.1.tar.gz
cd protobuf-3.5.1
./configure --build=i686-pc-linux-gnu CFLAGS="-m32 -DNDEBUG" CXXFLAGS="-m32 -DNDEBUG" LDFLAGS=-m32
make
make check
sudo make install
sudo ldconfig # refresh shared library cache.
cd ../
git clone https://github.com/rchain/rchain
cd rchain/rosette
./build.sh
apt -y install ./build.out/rosette-*.deb
rm ${rosette_install_dir}


