#!/bin/bash

# It is probably redundant if you set settings mentioned in https://gist.github.com/zekefast/42273658939724ba7c7a .
# But anyway it will not hurt anybody (sure if you are not putting your production database to RAM :)).
#
# Look for more detailed description in follow articles:
# - http://blog.vergiss-blackjack.de/2011/02/run-postgresql-in-a-ram-disk/
#
# ATTENTION: 
#  DO NOT apply this approach if you store important data in postgresql cluster, because that could cause 
#  loosing all your data in postgresql!
#
# OS: GNU/Linux Debian Wheezy
# 
# It should run on other systems without or with small modification.
# Here is a plan.
# 1. Stop postgres service.
# 2. Create tmpfs directory.
# 3. Mount tmpfs to newly create directory or add follow line to /etc/fstab to mount directory on system loading:
#    tmpfs	/mnt/tmpfs	tmpfs	size=768M,nr_inodes=10k,mode=0777	0	0
# 4. Synchronize existing database to directory where tmpfs was mounted.
# 5. Bind tmpfs mounted directory to postgres data_directory.
# 6. Start postgres service.

declare -r POSTGRES_SERVICE="/etc/init.d/postgresql"
declare -r POSTGRES_SERVICE_STOP_CMD="$POSTGRES_SERVICE stop"
declare -r POSTGRES_SERVICE_START_CMD="$POSTGRES_SERVICE start"
declare -r TMPFS_MOUNT_DIR="/mnt/tmpfs"
declare -r TMPFS_SIZE="768M" # in megabytes
declare -r POSTGRES_DIR="/var/lib/postgresql"


echo "Stoping postgres ... "
eval $POSTGRES_SERVICE_STOP_CMD && echo "done"

if [ ! -d $TMPFS_MOUNT_DIR ]; then
  mkdir -p "$TMPFS_MOUNT_DIR" &&
  chmod 0777 "$TMPFS_MOUNT_DIR" &&
  echo "Directory '$TMPFS_MOUNT_DIR' with 0777 credentials was created."
fi

mount | grep -Fq "$TMPFS_MOUNT_DIR"
if [ $? -ne 0 ]; then
  mount -t tmpfs -o size=$TMPFS_SIZE,nr_inodes=10k,mode=0777 tmpfs "$TMPFS_MOUNT_DIR" &&
  echo "RAM disk was mounted to $TMPFS_MOUNT_DIR."
else
  echo "Found: mounted RAM disk at $TMPFS_MOUNT_DIR."
fi

mount | grep -Fq "$POSTGRES_DIR"
if [ $? -ne 0 ]; then
  rsync --archive "$POSTGRES_DIR/" "$TMPFS_MOUNT_DIR/" &&
  echo "$POSTGRES_DIR/ was synchronized to RAM disk at $TMPFS_MOUNT_DIR/."
  mount -o bind "$TMPFS_MOUNT_DIR/" "$POSTGRES_DIR/" &&
  echo "RAM disk binded to $POSTGRES_DIR/."
else
  echo "Found: Binded RAM disk to $POSTGRES_DIR/."
fi

echo "Starting postgres ..."
