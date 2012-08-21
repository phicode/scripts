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

MAVEN_LATEST="apache-maven-3.0.4"
SCALA_LATEST="scala-2.9.2"

# load utility methods
. "$(dirname "$0")/../libsh.sh"

check_root

MAVEN_CHECK_BIN="/opt/maven/${MAVEN_LATEST}/bin/mvn"
MAVEN_SCRIPT="$(dirname "$0")/update_maven.sh"
MAVEN_REPO="http://mirror.switch.ch/mirror/apache/dist/maven/binaries"
MAVEN_EXT="-bin.tar.gz"

SCALA_CHECK_BIN="/opt/scala/${SCALA_LATEST}/bin/scala"
SCALA_SCRIPT="$(dirname "$0")/update_scala.sh"
SCALA_REPO="http://www.scala-lang.org/downloads/distrib/files"
SCALA_EXT=".tgz"

download_and_install() {
	name="$1"
	check_bin="$2"
	latest="$3"
	ext="$4"
	repo="$5"
	script="$6"
	if [ ! -e "$check_bin" ]; then
		FILE="${latest}${ext}"
		REPO_FILE="${repo}/${FILE}"
		STORE_FILE="/tmp/${FILE}"
		DL_LOG="${STORE_FILE}.download-log"

		if [ ! -e $STORE_FILE ]; then
			echo "downloading $name release: $latest"
			wget -o "${DL_LOG}" -O "$STORE_FILE" "$REPO_FILE"
			if [ $? -ne 0 ]; then
				echo "download failed, see: $DL_LOG"
				return
			fi
		fi

		${script} "$STORE_FILE"
	else
		echo "up-to-date: $name"
	fi
}


download_and_install "maven" "$MAVEN_CHECK_BIN" "$MAVEN_LATEST" "$MAVEN_EXT" "$MAVEN_REPO" "$MAVEN_SCRIPT"
download_and_install "scala" "$SCALA_CHECK_BIN" "$SCALA_LATEST" "$SCALA_EXT" "$SCALA_REPO" "$SCALA_SCRIPT"

