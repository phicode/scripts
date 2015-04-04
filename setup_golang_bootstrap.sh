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

# A script for setting up a go 1.4 bootstrap environment

GO_BRANCH="go1.4.2"
GO_PREFIX=/usr/local
GO_BOOTSTRAP="${GO_PREFIX}/go1.4"

if [ $(id -u) -ne 0 ]; then
	echo "must be run as root"
	exit 1
fi

[ "$(which gcc)" = "" ] && { echo "please install gcc" ; exit 1 ; }
[ "$(which git)" = "" ] && { echo "please install git" ; exit 1 ; }

die () {
	rm -rf "$GO_BOOTSTRAP"
	echo "aborting due to failure"
	exit 1
}

cd "$GO_PREFIX"

if [ ! -d "$GO_BOOTSTRAP" ]; then
	echo "cloning go repo for bootstrapping"
	git clone "https://github.com/golang/go" "$GO_BOOTSTRAP" || die
	cd "$GO_BOOTSTRAP"
else
	echo "updating go repo"
	cd "$GO_BOOTSTRAP"
	git fetch || die
fi

rm -rf bin pkg
git checkout "$GO_BRANCH" || die
git clean -f || die
git merge origin/"$GO_BRANCH"
cd src

./all.bash --clean || die

echo ""
echo "all done"
