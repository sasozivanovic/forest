#!/usr/bin/bash

verbose=""
compat=""
while [[ $1 ]] ; do
    if [[ $1 == "-v" ]] ; then
	verbose="-v"
    elif [[ $1 == "-compat" || $1 == "-c" ]] ; then
	compat="-compat $2"
	shift;
    fi
    shift;
done

# Clean
#find tex.stackexchange.com -type f \( -iname '*.tex' \; -iname '*.log' \; -iname '*.aux' \) -execdir echo {} \;

# Download questions
# TODO: don't dl what we've already got?
#wget -rE -l 1 -nc --accept-regex 'http://tex\.stackexchange\.com/questions/[0-9]*/[-a-z0-9]*' http://tex.stackexchange.com/questions/tagged/forest
#wget -rE -l 1 -nc --accept-regex 'http://tex\.stackexchange\.com/questions/[0-9]*/[-a-z0-9]*' http://tex.stackexchange.com/questions/tagged/forest?page=2&sort=newest&pagesize=50
#wget -rE -l 1 -nc --accept-regex 'http://tex\.stackexchange\.com/questions/[0-9]*/[-a-z0-9]*' http://tex.stackexchange.com/questions/tagged/forest?page=3&sort=newest&pagesize=50
#wget -rE -l 1 -nc --accept-regex 'http://tex\.stackexchange\.com/questions/[0-9]*/[-a-z0-9]*' http://tex.stackexchange.com/questions/tagged/forest?page=4&sort=newest&pagesize=50

# Extract code
#find tex.stackexchange.com -type f -iname '*.html' -execdir ../../../TeXSE-extract.py {} \;

# Test
find tex.stackexchange.com -maxdepth 3 -type f -path '*.tex' -execdir ../../../TeXSE-compile.sh $verbose $compat {} \;
