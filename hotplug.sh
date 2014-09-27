#!/bin/bash

# Copyright (c) 2014 Philipp Meinen <philipp@bind.ch>
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

scan() {
	for h in /sys/class/scsi_host/host*; do
		echo "- - -" > "${h}/scan"
	done
}

eject() {
	if [ $# -ne 2 ]; then
		echo "usage: $0 eject <device>"
		echo "   =>  $0 eject sdX"
		exit 1
	fi
	echo 1 > /sys/block/$2/device/delete
}

case "$1" in
	scan)	scan
		;;
	eject)  eject
		;;
	*)
		echo "usage: $0 (scan|eject)"
		;;
esac
