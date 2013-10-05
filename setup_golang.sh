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

# TODO: allow the user to select which branch he wants to use

GO_TOOLS="vet godoc cover"

[ "$(which gcc)" = "" ] && { echo "please install gcc"            ; exit 1 ; }
[ "$(which hg)" = "" ]  && { echo "please install mercurial (hg)" ; exit 1 ; }

die () {
	echo "aborting due to failure"
	exit 1
}

devdir="${HOME}/dev"
if [ ! -d $devdir ]; then
	echo "creating directory $devdir"
	mkdir "$devdir" || die
fi

cd "$devdir"

if [ ! -d "go" ]; then
	echo "cloning go repo"
	hg clone "https://code.google.com/p/go" || die
	cd go/src
else
	cd go
	echo "updating go repo"
	hg pull --update || die
	cd src
fi

./all.bash --clean

# additional archs
# choose from arch: 386 amd64 arm
#               os: linux windows darwin freebsd openbsd netbsd plan9
# build with env CGO_ENABLED=0 GOOS=... GOARCH=... go build ...

#env CGO_ENABLED=0 GOOS=windows GOARCH=amd64 ./make.bash --no-clean

setup_goroot="$HOME/dev/go"
setup_gobin="$HOME/dev/go/bin"
setup_mygo="$HOME/dev/mygo"
setup_goprofile="${HOME}/.goprofile"

echo "creating $setup_goprofile ..."
cat > "${setup_goprofile}" << EOF
# go environment setup
# this file is included from .profile and .bashrc

expr match "\$PATH" ".*${setup_gobin}.*" > /dev/null
if [ \$? -ne 0 ]; then
	export GOROOT="${setup_goroot}"
	export GOPATH="${setup_mygo}"
	export GOBIN="${setup_gobin}"
	export PATH="${setup_gobin}:\${PATH}"
	
	# 'go get' will install packages into the first directory of GOPATH
	# add further include paths for your other local projects in the file \${HOME}/.gopaths
	#  export GOPATH="\$GOPATH:/path/to/other/project"
	
	[ -f "\${HOME}/.gopaths" ] && . "\${HOME}/.gopaths"
fi
EOF

user_profile="${HOME}/.profile"
user_bashrc="${HOME}/.bashrc"
include_str=". ${setup_goprofile}"
search_include="^\. ${setup_goprofile}$"

grep "$search_include" "$user_profile" > /dev/null
if [ $? -ne 0 ]; then
	echo "adding an include for $setup_goprofile to $user_profile ..."
	echo "" >> "$user_profile"
	echo "$include_str" >> "$user_profile"
fi
grep "$search_include" $user_bashrc > /dev/null
if [ $? -ne 0 ]; then
	echo "adding an include for $setup_goprofile to $user_bashrc ..."
	echo "" >> "$user_bashrc"
	echo "$include_str" >> "$user_bashrc"
fi

. $setup_goprofile
for tool in $GO_TOOLS; do
	echo "installing/updating go-tool: $tool"
	go get -u "code.google.com/p/go.tools/cmd/$tool"
done

echo ""
echo "all done - you might need to restart shells which do not yet have the environment variables"
