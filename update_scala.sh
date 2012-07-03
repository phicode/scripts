#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <scala-distribution-archive>"
    exit 1
fi

file=$(basename "$1")

echo $file | grep -i 'tgz$' > /dev/null

if [ $? -ne 0 ]; then
    echo "Please provide a tgz archive"
    exit 2
fi

if [ $(whoami) != "root" ]; then
    echo "Please run this program as root"
    exit 3
fi

filenamelen=${#file}
fnlm4=$(($filenamelen-4)) # length without the ".tgz"
basename=${file::${fnlm4}}
dir=$(dirname "$1")
absdir=${dir}

# handle relativ paths
if [ ${dir::1} != "/" ]; then
    absdir=${PWD}/${dir}
fi

absfile=${absdir}/${file}
absextract=/opt/scala/${basename}

if [ ! -d /opt/scala ]; then
    echo "Creating directory /opt/scala"
    mkdir /opt/scala
fi

cd /opt/scala

echo "Extracting ${absfile} ..."
tar xzf "${absfile}"

if [ ! -d "${absextract}" ]; then
    echo "Cant find folder ${absextract}"
    exit 4
fi

rm -rf /opt/scala/current
echo "Using $absextract as the new scala distribution (through /opt/scala/current)"
ln -s ${absextract} /opt/scala/current

echo "Setting file access rights ..."
chown -R root:root /opt/scala
find /opt/scala -type d -exec chmod 755 '{}' ';'
find /opt/scala -type f -exec chmod 644 '{}' ';'
rm -f /opt/scala/current/bin/*.bat

function link() {
    from=$1
    to=$2

    if [ ! -L "${to}" ]; then
        echo "Linking $from to $to"
        ln -s "${from}" "${to}"
    fi
}

function executable() {
    from=$1
    to=$2

    if [ ! -x "${from}" ]; then
        echo "Making $from executable"
        chmod 755 "${from}"
    fi
}

link /opt/scala/current/bin/scala       /usr/local/bin/scala
link /opt/scala/current/bin/scalac      /usr/local/bin/scalac
link /opt/scala/current/bin/scalap      /usr/local/bin/scalap
link /opt/scala/current/bin/scaladoc    /usr/local/bin/scaladoc
link /opt/scala/current/bin/fsc         /usr/local/bin/fsc
link /opt/scala/current/bin/sbaz        /usr/local/bin/sbaz
link /opt/scala/current/bin/sbaz-setup  /usr/local/bin/sbaz-setup

executable /opt/scala/current/bin/scala
executable /opt/scala/current/bin/scalac
executable /opt/scala/current/bin/scalap
executable /opt/scala/current/bin/scaladoc
executable /opt/scala/current/bin/fsc
executable /opt/scala/current/bin/sbaz
executable /opt/scala/current/bin/sbaz-setup

if [ ! -d /usr/local/share/man/man1 ]; then
    echo "Creating /usr/local/share/man/man1"
    mkdir -p /usr/local/share/man/man1
fi

link /opt/scala/current/man/man1/scala.1     /usr/local/share/man/man1/scala.1
link /opt/scala/current/man/man1/scalac.1    /usr/local/share/man/man1/scalac.1
link /opt/scala/current/man/man1/scalap.1    /usr/local/share/man/man1/scalap.1
link /opt/scala/current/man/man1/scaladoc.1  /usr/local/share/man/man1/scaladoc.1
link /opt/scala/current/man/man1/fsc.1       /usr/local/share/man/man1/fsc.1
link /opt/scala/current/man/man1/sbaz.1      /usr/local/share/man/man1/sbaz.1

echo
echo "Done. You may want to add the following line to your ~/.bashrc :"
echo ". /opt/scala/current/misc/scala-tool-support/bash-completion/scala_completion.sh"
