check_root() {
        if [ $(whoami) != "root" ]; then
            echo "Please run this program as root"
            exit 1
        fi
}

check_extension() {
        file="$1"
        ext="$2"
        echo $file | grep -i "\\.${ext}$" > /dev/null
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

    if [ -e "${dst}" -a ! -x "${dst}" ]; then
        echo "Exec: $dst"
        chmod 755 "${dst}"
    fi
}

extract() {
        src="$1"
        dstdir="$2"
	extlen="$3"
	
	file=$(basename "$src")
	swname=$(expr substr $file 1 $((${#file}-$extlen)))
	srcdir=$(dirname "$1")
	abssrcdir="${dir}"

	# handle relativ paths
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

	tar xzf "${absfile}"

	if [ ! -d "$absextract" ]; then
	    echo "Cant find folder ${absextract}"
	    exit 1
	fi

	mk_link "$absextract" "${dstdir}/current"

	chown -R root:root "$dstdir"
	find "$absextract" -type d -exec chmod 755 '{}' ';'
	find "$absextract" -type f -exec chmod 644 '{}' ';'
}
