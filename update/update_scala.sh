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
    echo "Usage: $0 <scala-distribution-archive>"
    exit 1
fi

# load utility methods
. "$(dirname "$0")/../libsh.sh"

check_root
check_extension "$1" "\\.tgz"

# .tgz => 4
extract "$1" "/opt/scala" 4 "tar xzf"

localbin="/usr/local/bin"
localman="/usr/share/local/man"
srcdir="/opt/scala/current/bin"
srcman="/opt/scala/current/man"
executables="scala scalac scalap scaladoc fsc sbaz sbaz-setup"
manps="man1/scala.1 man1/scalac.1 man1/scalap.1 man1/scaladoc.1 man1/fsc.1 man1/sbaz.1"

for executable in ${executables}; do
	src="${srcdir}/${executable}"
	link="${localbin}/${executable}"
	mk_link "$src" "$link"
	mk_executable "$src"
done

for manp in ${manps}; do
	src="${srcman}/${manp}"
	link="${localman}/${manp}"
	man_dir=$(dirname "$link")
	if [ ! -d "$man_dir" ]; then
	    echo "Creating directory: ${man_dir}"
	    mkdir -p "$man_dir"
	fi
	mk_link "$src" "$link"
done

echo "Done!"
bc="/opt/scala/current/misc/scala-tool-support/bash-completion/scala_completion.sh"
if [ -e "$bc" ]; then
	echo "You may want to add the following line to your ~/.bashrc :"
	echo ". $bc"
fi
