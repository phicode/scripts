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

set -e

if [ $# -ne 1 ]; then
    echo "Usage: $0 <gradle-x.y-bin.zip>"
    exit 1
fi

# load utility methods
. "$(dirname "$0")/../libsh.sh"

check_root
check_extension "$1" "\\-bin\\.zip"
check_programs unzip

# -bin.zip => 8
extract "$1" "/opt/gradle" 8 "unzip -q -u"

src="/opt/gradle/current/bin/gradle"
link="/usr/local/bin/gradle"
mk_link "$src" "$link"
mk_executable "$src"

echo "Done!"
