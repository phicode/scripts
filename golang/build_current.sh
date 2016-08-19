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

# A script for setting up a go development environment

GO_PREFIX=/usr/local

export GOROOT_BOOTSTRAP="${GO_PREFIX}/go1.4"

if [ $# -ne 1 ]; then
	echo "usage: $0 <branch/tag>"
	echo ""
	echo "example: $0 master"
	echo "         $0 go1.4"
	echo ""
	echo "installs golang into ${GO_PREFIX}/go"
	exit 1
fi

if [ $(id -u) -ne 0 ]; then
	echo "must be run as root"
	exit 1
fi

[ "$(which gcc)" = "" ] && { echo "please install gcc" ; exit 1 ; }
[ "$(which git)" = "" ] && { echo "please install git" ; exit 1 ; }

die () {
	echo "aborting due to failure"
	exit 1
}

cd "$GO_PREFIX"
if [ ! -d "go" ]; then
	echo "cloning go repo"
	git clone "https://github.com/golang/go" || die
	cd go
else
	cd go
	echo "updating go repo"
	git fetch || die
fi
rm -rf bin pkg
git clean -f || die
git checkout $1 || die
git clean -f || die
git merge origin/$1
cd src

if [ -z $MAKE_ONLY ]; then
	./all.bash --clean || die
else
	./make.bash || die
fi

# additional archs
# choose from arch: 386 amd64 arm
#               os: linux windows darwin freebsd openbsd netbsd plan9
# build with env CGO_ENABLED=0 GOOS=... GOARCH=... go build ...

#env CGO_ENABLED=0 GOOS=windows GOARCH=amd64 ./make.bash --no-clean

echo ""
echo "all done"
