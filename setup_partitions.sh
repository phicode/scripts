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
drive="$1"

# load utility methods
. "$(dirname "$0")/libsh.sh"

check_root

PATH="/sbin:/usr/sbin:/bin:/usr/bin:${PATH}"
check_programs parted mkfs.ext2 mkfs.vfat

echo "partitioning device"
parted -s "$drive" mklabel msdos
parted -s "$drive" mkpart  primary ext2   "0%"  "40%"
parted -s "$drive" mkpart  primary fat32 "40%"  "60%"
parted -s "$drive" mkpart  primary       "60%" "100%"
parted -s "$drive" print

echo "formatting ${drive}1 with ext2"
mkfs.ext2 -q "${drive}1"

echo "formatting ${drive}2 with fat32"
mkfs.vfat -F32 "${drive}2"

$(dirname "$0")/init_crypto_partition.sh "${drive}3"
