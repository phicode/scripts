#!/bin/sh

# Copyright (c) 2012 Patrick Huber <stackmagic@gmail.com>
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

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <sublime2-distribution-archive>"
    exit 1
fi

# load utility methods
. "$(dirname "$0")/../libsh.sh"

check_root
check_extension "$1" "\\.tar\\.bz2"

# Sublime packages are named "Sublime Text 2.0.1 x64.tar.bz2" or
# "Sublime Text 2.0.1 x64.tar.bz2" which contains spaces and the extracted
# directory itself is named "Sublime Text 2" -- our libsh.sh doesn't like
# these special cases
base="/opt/sublime"
mkdir -p "${base}"

tmp="/tmp/update_sublime_$$"
mkdir -p "${tmp}"
tar xjf "${1}" -C "${tmp}"

version="$(basename "$1" | cut -d" " -f3)"
dest="${base}/sublime-${version}"
cp -r "${tmp}/Sublime Text 2" "${dest}"
rm -rf "${tmp}"

srcdir="/opt/sublime/current"
mk_link "${dest}" "${srcdir}"

localbin="/usr/local/bin"
mk_link "${srcdir}/sublime_text" "${localbin}/sublime"

echo "Done!"
