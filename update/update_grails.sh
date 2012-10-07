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

if [ $# -ne 1 ]; then
    echo "Usage: $0 <grails-distribution-archive>"
    exit 1
fi

# load utility methods
. "$(dirname "$0")/../libsh.sh"

check_root
check_extension "$1" "\\.zip"

# .zip => 4
extract "$1" "/opt/grails" 4 "unzip"

localbin="/usr/local/bin"
srcdir="/opt/grails/current/bin"
executables="grails startGrails"

for executable in ${executables}; do
	src="${srcdir}/${executable}"
	link="${localbin}/${executable}"
	mk_link "$src" "$link"
	mk_executable "$src"
done

echo "Done!"
