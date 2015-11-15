#!/usr/bin/bash
viewemacs=''
viewfirst=''
viewsecond=''
viewdiff=''
viewfolder=''
viewall='1'
while [[ ${1:0:1} == '-' ]] ; do
    viewall=''
    if [[ $1 == '-emacs' ]] ; then viewemacs='1' ; fi
    if [[ $1 == '-first' ]] ; then viewfirst='1' ; fi
    if [[ $1 == '-second' ]] ; then viewsecond='1' ; fi
    if [[ $1 == '-diff' ]] ; then viewdiff='1' ; fi
    if [[ $1 == '-folder' ]] ; then viewfolder='1' ; fi
    shift;
done
if [[ $viewall ]] ; then
    viewemacs='1'
    viewfirst='1'
    viewsecond='1'
    viewdiff='1'
    viewfolder='1'
fi
if [[ $1 == "Testing" ]] ; then
    dir="tex.stackexchange.com/questions/${2%/*}"
    fn=${2##*/}
    n=${fn%%.*}
    engine=$3
else
    dir=${1%/*}
    fn=${1##*/}
    n=${fn%%.*}
    engine=${fn%.*}
    engine=${engine##*.}
fi
if [[ $viewfolder && -d $PWD/$dir ]] ; then thunar $PWD/$dir >/dev/null 2>/dev/null & fi
#emacsclient -nce "(progn (find-file \"$PWD/$dir/$engine-v1.0/$n.tex\") (find-file \"$PWD/$dir/$engine-v1.1/$n.tex\"))"
if [[ $viewemacs && -f $PWD/$dir/$engine-v1.1/$n.tex ]] ; then emacsclient -nc $PWD/$dir/$engine-v1.1/$n.tex $PWD/$dir/$engine-v1.0/$n.tex >/dev/null 2>/dev/null ; fi
if [[ $viewfirst && -f $dir/$engine-v1.0/$n.pdf ]] ; then atril $dir/$engine-v1.0/$n.pdf >/dev/null 2>/dev/null & fi
if [[ $viewsecond && -f $dir/$engine-v1.1/$n.pdf ]] ; then atril $dir/$engine-v1.1/$n.pdf >/dev/null 2>/dev/null & fi
if [[ $viewdiff && -f $dir/$engine-v1.0/$n.pdf && -f $dir/$engine-v1.1/$n.pdf ]] ; then diffpdf -a $dir/$engine-v1.0/$n.pdf $dir/$engine-v1.1/$n.pdf >/dev/null 2>/dev/null & fi
