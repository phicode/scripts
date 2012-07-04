#!/bin/bash
# Copyright (c) 2012 Philipp Meinen <philipp@bind.ch>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

##########################################
#       SETUP                            #
##########################################
# 1. create partitions
# 2. cryptsetup luksFormat /dev/sdXy
# 3. cryptsetup luksOpen /dev/sdXy name
# 4. mkfs.ext2 /dev/mapper/name
# 5. for UUID of the LUKS partition:
#         cryptsetup luksUUID /dev/sdXy
# 6. ext2 fs UUID:
#         tune2fs -l /dev/mapper/sd_backup | grep UUID
# 7.
#    in /etc/fstab:
#    UUID=put-ext2-fs-uuid-here /mnt/backup  auto  user,noauto,noatime,nodiratime  0  0

##########################################
#       CHANGELOG                        #
#                                        #
# 0.1.0 : Initial release                #
##########################################

##########################################
#       TODO                             #
# - Config in ~/.xxx                     #
# - setup script                         #
##########################################

##########################################
#       CONFIGURATION                    #
##########################################
BACKUP_USER=root
MOUNTPOINT=/mnt/backup
RSYNC_BACKUP_CMD="rsync --archive --delete --human-readable"
RSYNC_RESTORE_CMD="rsync --archive --human-readable"
DATA_BASEDIR=/home/phil
BACKUP_BASEDIR=$MOUNTPOINT

BACKUP_DIRS="admin conf dev fh kochen literature misc multimedia webcomics Pictures .config .ssh .kde"
BACKUP_FILES="backup.sh .hgrc"

LUKS_UUID="dc70a04a-0cb4-4e5f-ae6e-dc84ece106e6"
LUKS_MAP_NAME="luks_sd_backup"

#########################################
#     SCRIPT - TOUCH WITH CARE          #
#########################################

if [ $(whoami) != ${BACKUP_USER} ]; then
    echo "ERROR: run this script as user: ${BACKUP_USER}"
    exit 1
fi

CRYPTSETUP="/sbin/cryptsetup"
if [ ! -x ${CRYPTSETUP} ]; then
	echo "ERROR: ${CRYPTSETUP} does not exist"
	exit 1
fi

LUKS_PARTITON=""
search_luks_partition() {
	for part in /dev/sd* ; do
		$CRYPTSETUP isLuks $part
		if [ $? -eq 0 ]; then
			PUUID=$($CRYPTSETUP luksUUID $part)
			if [ $PUUID = $LUKS_UUID ]; then
				LUKS_PARTITION=$part
			fi
		fi
	done
	if [ -z $LUKS_PARTITION ]; then
		echo "ERROR: no LUKS partition found for UUID: ${LUKS_UUID}"
		exit 1
	fi
}

do_mount() {
	if [ ! -e /dev/mapper/${LUKS_MAP_NAME} ]; then
		search_luks_partition
		$CRYPTSETUP luksOpen $LUKS_PARTITION $LUKS_MAP_NAME
		if [ $? -ne 0 ]; then
			echo "ERROR: opening the luks partition $LUKS_PARTITION failed!"
			exit 1
		fi
	else
		echo "LUKS partition is already mapped"
	fi
	STATUS=$(mount | grep " on $MOUNTPOINT type ")
	if [ -z "$STATUS" ]; then
    		echo "mounting the backup drive ..."
    		mount $MOUNTPOINT
    		if [ $? -ne 0 ]; then
			echo "ERROR: mount failed"
        		exit 1
    		fi
	else
		echo "Backup partition is already mounted"
	fi
}

do_umount() {
	umount ${MOUNTPOINT}
	if [ $? -ne 0 ]; then
		echo "WARNING: unmounting ${MOUNTPOINT} failed!"
	fi
	$CRYPTSETUP luksClose ${LUKS_MAP_NAME}
	if [ $? -ne 0 ]; then
		echo "WARNING: closing LUKS partition with name ${LUKS_MAP_NAME} failed!"
	fi
}

do_backup () {
	echo "backup mode selected"
	RSYNC_CMD=$RSYNC_BACKUP_CMD
	RSYNC_FROM=$DATA_BASEDIR
	RSYNC_TO=$BACKUP_BASEDIR
	PRINT_PREFIX="backing up"
	do_rsync
}

do_restore () {
	echo "restore mode selected"
	RSYNC_CMD=$RSYNC_RESTORE_CMD
	RSYNC_FROM=$BACKUP_BASEDIR
	RSYNC_TO=$DATA_BASEDIR
	PRINT_PREFIX="restoring from"
	do_rsync
}

#echo rsync:      $RSYNC_CMD
#echo rsync-from: $RSYNC_FROM
#echo rsync-to:   $RSYNC_TO

#exit 5
#RSYNC_CMD="echo $RSYNC_CMD"

do_rsync() {
if [ -z "$BACKUP_DIRS" ]; then
	echo "BACKUP_DIRS is not set"
	exit 1
fi
# --verbose
for dir in $BACKUP_DIRS; do
    from=${RSYNC_FROM}/$dir/
    to=${RSYNC_TO}/$dir
    echo "$PRINT_PREFIX $from to $to ..."
    $RSYNC_CMD "$from" "$to"
done

for file in $BACKUP_FILES; do
    from=${RSYNC_FROM}/$file
    to=${RSYNC_TO}/$file
    echo "$PRINT_PREFIX $from to $to ..."
    $RSYNC_CMD "$from" "$to"
done

echo -n "syncing ... "
sync
echo "done"

percent_line=$(df -h $MOUNTPOINT | grep $MOUNTPOINT | cut -d'%' -f1)
pl_length=${#percent_line}
percent_start=$((${pl_length}-2))
percent=${percent_line:${percent_start}}

echo
echo "backup medium on $MOUNTPOINT is ${percent}% full"
}

case "$1" in
	mount)	do_mount
		;;
	umount) do_umount
		;;
	restore)
		do_mount
		do_restore
		;;
	backup)
		do_mount
		do_backup
		;;
	*)
		echo "usage: $0 (mount|umount|backup|restore)"
		;;
esac
