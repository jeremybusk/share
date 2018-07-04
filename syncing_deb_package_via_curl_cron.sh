#!/usr/bin/env bash
branch="dev"
file=$(curl -s -L https://repo.pyr8.io/rchain/downloads/${branch}/ | grep "rnode.*.deb" | grep -Po 'href="\K.*?(?=")')
app_root_dir="/srv/app/rnode"
last_update_time=$(cat ${app_root_dir}/last_update_time)
live_update_time=$(curl --silent --remote-time --head https://repo.pyr8.io/rchain/downloads/${branch}/rnode_0.4.2_all.deb | grep ^Last-Modified:)

if [[ ${last_update_time} != ${live_update_time} && ! -f "${app_root_dir}/lock" ]]; then
  touch "${app_root_dir}/lock"
  date
  echo "Updating rnode because package has been updated"
  echo "Using file ${file} with timestamp ${live_update_time}"
  curl -s --remote-time https://repo.pyr8.io/rchain/downloads/${branch}/${file} --output ${app_root_dir}/rnode-${branch}-latest.deb
  ${app_root_dir}/stop.sh
  apt -y remove rnode
  apt -y install ${app_root_dir}/rnode-${branch}-latest.deb
  curl --silent --head https://repo.pyr8.io/rchain/downloads/${branch}/${file} | grep ^Last-Modified: > ${app_root_dir}/last_update_time
  sleep 3
  ${app_root_dir}/start.sh
  rm "${app_root_dir}/lock"
fi
