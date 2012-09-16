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

# load utility methods
. "$(dirname "$0")/libsh.sh"

check_programs go

# expected go home
EXP_GO_PATH="$HOME/dev/go"
EXP_GO_BIN="$EXP_GO_PATH/bin"
EXP_GO_SRC="$EXP_GO_PATH/src"
EXP_GO_PKG="$EXP_GO_PATH/pkg"
GO_PROFILE="$HOME/.goprofile"
PROFILE="$HOME/.profile"
BASHRC="$HOME/.bashrc"
INCLUDE_STR=". $GO_PROFILE"

ALL_OK=1
DO_CREATE_DIRS=""
DO_CREATE_GOPROFILE=0
DO_APPEND_BASHRC=""
DO_APPEND_PROFILE=""

# create go-home and go-bin if they dont exist
if [ ! -d "$EXP_GO_PATH" ]; then
	DO_CREATE_DIRS="$DO_CREATE_DIRS $EXP_GO_PATH"
	ALL_OK=0
fi
if [ ! -d "$EXP_GO_BIN" ]; then
	DO_CREATE_DIRS="$DO_CREATE_DIRS $EXP_GO_BIN"
	ALL_OK=0
fi
if [ ! -d "$EXP_GO_SRC" ]; then
	DO_CREATE_DIRS="$DO_CREATE_DIRS $EXP_GO_SRC"
	ALL_OK=0
fi
if [ ! -d "$EXP_GO_PKG" ]; then
	DO_CREATE_DIRS="$DO_CREATE_DIRS $EXP_GO_PKG"
	ALL_OK=0
fi
if [ ! -f "$GO_PROFILE" ]; then
	DO_CREATE_GOPROFILE=1
	ALL_OK=0
fi

grep "$INCLUDE_STR" $PROFILE > /dev/null
if [ $? -ne 0 ]; then
	DO_APPEND_PROFILE="$INCLUDE_STR"
	ALL_OK=0
fi
grep "$INCLUDE_STR" $BASHRC > /dev/null
if [ $? -ne 0 ]; then
	DO_APPEND_BASHRC="$INCLUDE_STR"
	ALL_OK=0
fi

if [ $ALL_OK -eq 1 ]; then
	echo "your go installation should be ready"
	exit 0
fi

echo ""
echo "this script will do the following"
echo "----------------------------------"
for d in $DO_CREATE_DIRS; do
echo "create directory $d"
done
[ $DO_CREATE_GOPROFILE -ne 0 ] && \
echo "add $GO_PROFILE"
[ "$DO_APPEND_BASHRC" != "" ] && \
echo "include $GO_PROFILE from $BASHRC"
[ "$DO_APPEND_PROFILE" != "" ] && \
echo "include $GO_PROFILE from $PROFILE"
echo "----------------------------------"
echo ""
echo -n "would you like to proceed? "
read_yes_no
if [ $? -ne 0 ]; then
	echo "aborting"
	exit 1
fi

for d in $DO_CREATE_DIRS; do
	mkdir -p "$d"
done

if [ $DO_CREATE_GOPROFILE -ne 0 ]; then
	cat > "${GO_PROFILE}" << EOF

export GOBIN="$EXP_GO_BIN"
export GOPATH="$EXP_GO_PATH"

PATH="\${GOBIN}:\${PATH}"

EOF
fi

if [ "$DO_APPEND_BASHRC" != "" ]; then
	echo "$INCLUDE_STR" >> "$BASHRC"
fi
if [ "$DO_APPEND_PROFILE" != "" ] ; then
	echo "$INCLUDE_STR" >> "$PROFILE"
fi