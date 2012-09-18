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
    echo "Usage: $0 <partition>"
    exit 1
fi
partition="$1"

# load utility methods
. "$(dirname "$0")/libsh.sh"

PATH="/sbin:/usr/sbin:/bin:/usr/bin:${PATH}"

fstype="ext2"
check_programs "mkfs.$fstype" cryptsetup tune2fs
mkfs_bin="$(which mkfs.$fstype)"

cryptsetup                   \
	--cipher aes-xts-plain64 \
	--hash sha256            \
	--key-size 512           \
	--verify-passphrase      \
	--use-random             \
	luksFormat "$partition"

if [ $? -ne 0 ]; then
	echo "exiting"
	exit
fi

LUKS_UUID=$(cryptsetup luksUUID "$partition")
echo "The UUID of the newly created LUKS container is: $LUKS_UUID"

init_name="init_crypto_$$"

cryptsetup luksOpen "$partition" "$init_name"
cryptsetup status "$init_name"

if [ $? -ne 0 ]; then
	echo "failed to open the new luks partition, exiting"
	exit
fi

echo "creating $fstype filesystem ..."
$mkfs_bin -q "/dev/mapper/$init_name"

tune2fs -l "/dev/mapper/$init_name" | grep UUID

sync
sleep 2

cryptsetup luksClose "$init_name"

echo ""
echo ""
