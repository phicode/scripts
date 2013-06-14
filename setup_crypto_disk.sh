#!/bin/sh

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

if [ $# -ne 1 ]; then
    echo "Usage:   $0 <drive>"
    echo "Example: $0 /dev/sdc"
    exit 1
fi
PATH="/sbin:/usr/sbin:/bin:/usr/bin:${PATH}"
fstype="ext2"

drive="$1"
crypt_partition="${drive}1"

# load utility methods
. "$(dirname "$0")/libsh.sh"
check_root
check_programs parted mkfs.${fstype} cryptsetup tune2fs

echo "partitioning device"
parted -s "$drive" mklabel msdos
parted -s "$drive" mkpart  primary  "0%" "100%"
parted -s "$drive" print

#echo "formatting ${drive}1 with $fstype ..."
#mkfs.${fstype} -q "${drive}1"

echo "creating crypto container in $crypt_partition"
cryptsetup                   \
	--cipher aes-xts-plain64 \
	--hash sha256            \
	--key-size 256           \
	--verify-passphrase      \
	--use-random             \
	luksFormat "$crypt_partition"

if [ $? -ne 0 ]; then
	echo "exiting"
	exit
fi

LUKS_UUID=$(cryptsetup luksUUID "$crypt_partition")
echo "The UUID of the newly created LUKS container is: $LUKS_UUID"

init_name="luks_$(basename $crypt_partition)"

cryptsetup luksOpen "$crypt_partition" "$init_name"
cryptsetup status "$init_name"

if [ $? -ne 0 ]; then
	echo "failed to open the new luks partition, exiting"
	exit
fi

echo "formatting partition inside crypto container $crypt_partition with $fstype ..."
mkfs.${fstype} -q "/dev/mapper/$init_name"

tune2fs -l "/dev/mapper/$init_name" | grep UUID

echo "syncing ..."
sync

# prevent io-device-busy error which happens when closing the device too early
sleep 1
sync
sleep 1

echo "closing crypto container ..."
cryptsetup luksClose "$init_name"

echo ""
echo ""

exit 0

# TODO: cryptmount entry for users
#       create a discovery script to find crypto containers
# container: a617ca77-becf-4ac6-98b2-71f9413a4a47
# fs:        29077443-e8ce-4911-bc94-4c93ccbf9e04

