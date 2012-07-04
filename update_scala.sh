#!/bin/sh

if [ $# -ne 1 ]; then
    echo "Usage: $0 <scala-distribution-archive>"
    exit 1
fi

# load utility methods
. "$(dirname "$0")/libsh.sh"

check_root
check_extension "$1" "tgz"

# .tgz => 4
extract "$1" "/opt/scala" 4

localbin="/usr/local/bin"
localman="/usr/share/local/man"
srcdir="/opt/scala/current/bin"
srcman="/opt/scala/current/man"
executables="scala scalac scalap scaladoc fsc sbaz sbaz-setup"
manps="man1/scala.1 man1/scalac.1 man1/scalap.1 man1/scaladoc.1 man1/fsc.1 man1/sbaz.1"

for executable in ${executables}; do
	src="${srcdir}/${executable}"
	link="${localbin}/${executable}"
	mk_link "${src}" "${link}"
	mk_executable "${src}"
done

for manp in ${manps}; do
	src="${srcman}/${manp}"
	link="${localman}/${manp}"
	man_dir=$(dirname "${link}")
	if [ ! -d "${man_dir}" ]; then
	    echo "Creating directory: ${man_dir}"
	    mkdir -p "${man_dir}"
	fi
	mk_link "${src}" "${link}"
done

echo
echo "Done. You may want to add the following line to your ~/.bashrc :"
echo ". /opt/scala/current/misc/scala-tool-support/bash-completion/scala_completion.sh"
