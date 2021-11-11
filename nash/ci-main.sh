#!/usr/bin/env bash
set -ex
shopt -s expand_aliases


if echo "$GITHUB_BASE_REF $GITHUB_REF" | grep -q "dev"; then
  echo "Running PR to branch dev."
  export ENV=dev
  echo "$ENV_DEV" > .env
elif echo "$GITHUB_BASE_REF $GITHUB_REF" | grep -q "prod"; then
  echo "Running PR to branch prod."
  export ENV=prod
  echo "$ENV_PROD" > .env
else
  echo "Unsupported GITHUB_BASE_REF branch with name $GITHUB_HEAD_REF."
  exit 1
fi

. .env

echo ENV: $ENV


ssh_host=$SSH_HOST
ssh_user=$SSH_USER
ssh_conn=$SSH_USER@$SSH_HOST
ssh_id_file=.ssh/id
mkdir -p .ssh
echo "$SSH_KNOWN_HOSTS" > .ssh/known_hosts
# SSH_SECRET_KEY=$(echo "$SSH_SECRET_KEY" | base64 -d)
SSH_SECRET_KEY=$(echo "$SUDO_SECRET_SSHKEY" | base64 -d)
echo "$SSH_SECRET_KEY" > $ssh_id_file
sudo chmod 600 $ssh_id_file
ssh_opts="-o StrictHostKeyChecking=yes \
  -o UserKnownHostsFile=.ssh/known_hosts \
  -o ConnectionAttempts=10"
ssh_cmd="ssh -p 22 -i $ssh_id_file ${ssh_opts}"
ssh_cmd="ssh -p 22 -i $ssh_id_file ${ssh_opts}"
alias ssh="${ssh_cmd}"
alias scp="scp -P 22 -i $ssh_id_file ${ssh_opts}"
# alias rsync="rsync -avz --delete --rsync-path=\"sudo rsync\" -e \"${ssh_cmd}\""
# alias rsync="rsync -avz --dry-run --delete --exclude=".*" --rsync-path=\"sudo rsync\" -e \"${ssh_cmd}\""
alias rsync="rsync -og --chown=$SSH_USER:$SSH_USER -avz --delete --exclude=".*" --rsync-path=\"sudo rsync\" -e \"${ssh_cmd}\""



enableSSHAgent(){
  pkill ssh-agent || true
  eval `ssh-agent`
  ssh-add - <<< $(echo "$SUDO_SECRET_SSHKEY" | base64 -d)
  grep $SSH_KNOWN_HOSTS || echo "$SSH_KNOWN_HOSTS" >> ~/.ssh/known_hosts
}


testConn(){
  # echo $ssh
  # exit
  # prepSsh
  # echo $ssh_cmd
  ssh $ssh_conn whoami
  # ssh $ssh_conn hostname
  exit
}

main(){
  # enableSSHAgent
  # prepSsh
  # testConn
 # exit
  # enableSSHAgent
  # rsync files/ $ssh_conn:~/files
  rsync . $ssh_conn:~/ci
  ssh $ssh_conn "cd ci/dns; ./main.sh"
}

main
