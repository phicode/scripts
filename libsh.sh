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

check_root() {
    if [ $(whoami) != "root" ]; then
        echo "Please run this program as root"
        exit 1
    fi
}

check_extension() {
    file="$1"
    ext="$2"
    echo $file | grep -i "${ext}$" > /dev/null
    if [ $? -ne 0 ]; then
        echo "extension missmatch, expected: $ext"
        exit 1
    fi
}

mk_link() {
    src=$1
    link=$2

    if [ -e "$src" ]; then
        if [ -L "$link" ]; then
		rm "$link"
	fi
        echo "Link: $link -> $src"
        ln -s "$src" "$link"
    else
        if [ -L "$link" ]; then
                echo "WARN: removing old link: $link"
                rm "$link"
        fi
    fi
}

mk_executable() {
    dst=$1

    if [ -e "$dst" -a ! -x "$dst" ]; then
        echo "Exec: $dst"
        chmod 755 "$dst"
    fi
}

extract() {
    src="$1"
    dstdir="$2"
	extlen="$3"
    cmd="$4"
	
	file=$(basename "$src")
	swname=$(expr substr $file 1 $((${#file}-$extlen)))
	srcdir=$(dirname "$1")
	abssrcdir="$srcdir"

	# handle relative paths
	if [ $(expr index "$srcdir" /) -ne 1 ]; then
	    abssrcdir="${PWD}/${srcdir}"
	fi

	absfile="${abssrcdir}/${file}"
	absextract="${dstdir}/${swname}"

	echo "extracting '$swname' from '$abssrcdir' to '$dstdir'"

	if [ ! -d "$dstdir" ]; then
		echo "Creating directory $dstdir"
		mkdir -p "$dstdir"
	fi
    cd "$dstdir"

	${cmd} "$absfile"

	if [ ! -d "$absextract" ]; then
	    echo "Cant find folder $absextract"
	    exit 1
	fi

	mk_link "$absextract" "${dstdir}/current"

	chown -R root:root "$dstdir"
	find "$absextract" -type d -exec chmod 755 '{}' ';'
	find "$absextract" -type f -exec chmod 644 '{}' ';'
}
