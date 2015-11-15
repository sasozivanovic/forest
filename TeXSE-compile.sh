#!/usr/bin/bash

while [[ $1 ]] ; do
    if [[ $1 == "-v" ]] ; then
	verbose="1"
    else
	break
    fi
    shift;
done

function append_filevars () {
    echo "
%%% Local Variables:
%%% mode: latex
%%% TeX-master: t
%%% TeX-engine: ${2%latex}tex
%%% End:" >> $1
}

# OK: compiles
function test () {
    # $1=file, $2=engine
    if [[ ! ( -a $1.$2.ok || -a $1.$2.OK || -a $1.$2.bad || -a $1.$2.BAD || -a $1.$2.ignore ) ]] ; then
	dir=`pwd`
	echo -n "Testing ${dir##*/}/${1#./} $2 ..."
	mkdir $2-v1.0 2>/dev/null
	cd $2-v1.0
	ln -sf ../../../../versions/1.0.10/forest/forest.sty
	rm -rf ${1%tex}*
	cp ../$1 .
	append_filevars $1 $2
	if timeout -k 10s 5m $2 -interaction batchmode $1 >/dev/null ; then 
    	    mkdir ../$2-v1.1 2>/dev/null
	    cd ../$2-v1.1
	    ln -sf ../../../../forest.sty ../../../../forest-lib-*.sty .
	    rm -rf ${1%tex}*
	    cp ../$1 .
	    append_filevars $1 $2
	    if $2 -interaction batchmode $1 >/dev/null ; then
		echo -n "v1.1 compiles, ok "
		if cmp ../$2-v1.0/${1%tex}pdf ${1%tex}pdf >/dev/null ; then
		    echo -n "pdf are completely the same ... OK " ;
		    touch ../$1.$2.OK
		else
		    # from http://stackoverflow.com/questions/6469157/pdf-compare-on-linux-command-line
		    gs -o ../$2-v1.0/${1%tex}ppm -sDEVICE=ppmraw -r300 ../$2-v1.0/${1%tex}pdf >/dev/null
		    gs -o ${1%tex}ppm -sDEVICE=ppmraw -r300 ${1%tex}pdf >/dev/null
		    if cmp ../$2-v1.0/${1%tex}ppm ${1%tex}ppm >/dev/null ; then
			echo -n "pdf are the same ... OK " ;
			touch ../$1.$2.OK
		    else
			gs -o ../$2-v1.0/${1%tex}ppm -sDEVICE=ppmraw -r600 ../$2-v1.0/${1%tex}pdf >/dev/null
			gs -o ${1%tex}ppm -sDEVICE=ppmraw -r600 ${1%tex}pdf >/dev/null
			if cmp ../$2-v1.0/${1%tex}ppm ${1%tex}ppm >/dev/null ; then
			    echo -n "pdf are the same ... OK " ;
			    touch ../$1.$2.OK
			else
			    echo -n "DIFFER! bad "
			    touch ../$1.$2.bad
			fi
		    fi
		    rm ../$2-v1.0/${1%tex}ppm ${1%tex}ppm
		fi
	    else
		echo -n "v1.1 DOES NOT COMPILE!, BAD"
		touch ../$1.$2.BAD
	    fi
	else
	    echo -n "v1.0 does not compile, ignore "
	    touch ../$1.$2.ignore
	fi
	cd ..
	echo
    else
	if [[ $verbose ]] ; then echo -n "$info" ; fi
    fi
}

test $1 pdflatex 
test $1 xelatex 
test $1 lualatex 
