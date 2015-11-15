#!/usr/bin/bash

verbose=""
while [[ $1 ]] ; do
    if [[ $1 == "-v" ]] ; then
	verbose="-v"
    fi
    shift;
done

# clean
#find tex.stackexchange.com -type f \( -iname '*.tex' \; -iname '*.log' \; -iname '*.aux' \) -execdir echo {} \;

# Download questions
# TODO: don't dl what we've already got?
#wget -rE -l 1 --accept-regex 'http://tex\.stackexchange\.com/questions/[0-9]*/[-a-z0-9]*' http://tex.stackexchange.com/questions/tagged/forest
#wget -rE -l 1 --accept-regex 'http://tex\.stackexchange\.com/questions/[0-9]*/[-a-z0-9]*' http://tex.stackexchange.com/questions/tagged/forest?page=2&sort=newest&pagesize=50
#wget -rE -l 1 --accept-regex 'http://tex\.stackexchange\.com/questions/[0-9]*/[-a-z0-9]*' http://tex.stackexchange.com/questions/tagged/forest?page=3&sort=newest&pagesize=50

# Extract code
#find tex.stackexchange.com -type f -iname '*.html' -execdir ../../../TeXSE-extract.py {} \;
find tex.stackexchange.com -maxdepth 3 -type f -path '*.tex' -execdir ../../../TeXSE-compile.sh $verbose {} \;
