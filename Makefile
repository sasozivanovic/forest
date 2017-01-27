INTERACTION = batchmode
SINGLEPASS = no
EXTERNALIZE = yes

package-ins = forest.ins
doc-ins = forest-doc.ins
ins = ${package-ins} ${doc-ins}

dtx = $(shell grep -Poh '\\from{(.*?)}' $(ins) | sed 's/\\from{\(.*\)}/\1/;' | sort | uniq)

package-tex = 
package-nonderived-sty = forest-compat.sty
package-derived-sty = $(shell grep -Poh '\\file{(.*?)}' $(package-ins) | sed 's/\\file{\(.*\)}/\1/;')
package-sty = $(package-nonderived-sty) $(package-derived-sty)
package-other =
package-pdf = forest.pdf

doc-tex = forest-doc.tex
doc-nonderived-sty = forest-doc.sty
doc-derived-sty = $(shell grep -Poh '\\file{(.*?)}' $(doc-ins) | sed 's/\\file{\(.*\)}/\1/;')
doc-sty = $(doc-nonderived-sty) $(doc-derived-sty)
doc-other = forest-doc.ist tex.bib
doc-pdf = forest-doc.pdf

tex = $(package-tex) $(doc-tex)
sty = $(package-sty) $(doc-sty)
other = $(package-other) $(doc-other)
pdf = $(package-pdf) $(doc-pdf)

%.success: % ;

forest-doc.pdf: forest-doc.tex forest-doc.tex.success $(dtx) $(doc-sty) $(doc-other) forest-doc-test.tex
	$(call externalize, $(<:.success=))
	@echo
	@echo Pass 1 ...
	$(call compile, $(<:.success=))
ifneq ($(SINGLEPASS),yes)
	@rm forest-doc.memo
	@echo
	@echo Pass 2 ...
	$(call compile, $(<:.success=))
	@echo
	@echo Pass 3 ...
	$(call compile, $(<:.success=))
	@echo
	@echo Pass 4 ...
	$(call compile, $(<:.success=))
endif
	@echo Compilation successful!
	@touch -r $< $<.success

forest-doc-test.tex:
	[[ -a $@ ]] || touch $@

forest.pdf: forest.dtx.success forest.sty 
	$(call externalize, $(<:.success=))
	@echo Pass 1 ...
	$(call compile, $(<:.success=))
ifneq ($(SINGLEPASS),yes)
	@echo
	@echo Pass 2 ...
	$(call compile, $(<:.success=))
endif
	@echo Compilation successful!
	@touch -r $(<:.success=) $<

externalize = if [[ "$(EXTERNALIZE)" == 'yes' ]] ; then \
	echo Externalization is ON. ; echo "\\tikzexternalize" > $1-externalize.tex ; else \
	echo Externalization is OFF. ; echo "" > $1-externalize.tex ; fi 

compile = time pdflatex -synctex=1 -interaction $(INTERACTION) $(1) && \
	( bibtex $(basename $1) || ( echo bibtex failed! && true ) ) && \
	( if [[ -f $(basename $1).idx ]] ; then makeindex -s forest-doc.ist $(basename $1) ; fi || ( echo makeindex failed! && true ) ) && \
	if [[ `pdfinfo $(basename $1).pdf | sed -n '/^Pages:/s/^Pages: *//p'` > 10 ]] ; then cp $(basename $1).pdf $(basename $1).bak.pdf ; fi

forest.sty: forest.dtx forest.ins
	tex forest.ins >/dev/null

forest-lib-%.sty: forest-libs.dtx forest.ins
	tex forest.ins >/dev/null

forest-index.sty: forest-index.dtx forest-doc.ins
	tex forest-doc.ins >/dev/null

sty: 
	@echo Generating .sty ...
	tex forest.ins >/dev/null
	tex forest-doc.ins >/dev/null

README: readme.tex forest.sty
	@echo Generating README ...
	pdflatex -interaction batchmode readme >/dev/null
	mv README.txt README

VERSION: version.tex forest.sty
	pdflatex -interaction batchmode version >/dev/null
	mv VERSION.txt VERSION
	@echo forest v`cat VERSION`

versiondir: VERSION
	@echo Creating version directory ...
	mkdir -p versions
	mkdir versions/`cat VERSION`
	mkdir versions/`cat VERSION`/forest

versiondirremove: VERSION
	@if [[ -d versions && -d versions/`cat VERSION` ]] ; then read -p "Remove forest v`cat VERSION` (y/n)? " jane ; if [ "$$jane" = "y" ] ; then rm -r versions/`cat VERSION` ; echo Removed it! ; else echo "Ok, I won't!" ; exit 1; fi ; fi

%.dtx.checksum: %.dtx
	@cat $< | tr -cd '\\' |wc -m > $@
	@sed -ne '1 s/^% *\\CheckSum{\([0-9\]*\)\} *$$/\1/p;' $< | \
		if ! diff $@ - >/dev/null ; then \
			checksum=`cat $@` ; \
			echo Fixing checksum in $< to $$checksum ; \
			sed -ie "1 s/\\CheckSum{\([0-9]*\)}/\\CheckSum{$$checksum}/;" $< ; \
		fi


nocheckexternalization : ;

checkexternalization :
	@echo Checking if externalization is off ...
	@if grep '^[^%]\\tikzexternalize$$' forest-doc.tex >/dev/null || [[ "$(EXTERNALIZE)" == 'yes' ]] ; then echo ; echo Switch off externalization! ; echo; exit 1; fi

checksums: $(patsubst %.dtx,%.dtx.checksum,$(dtx))

# Sometimes this will be too strict (e.g. when updating only one library).
# In such a case, temporarily rename "checkreleasedate" to "nocheckreleasedate" in "zip:".
checkreleasedate: $(ins) $(dtx) $(sty) $(tex) $(other)
	@echo Checking release dates ...
	@! grep "Copyright (c) 2012-.*Saso Zivanovic" $^ | grep -v `date +%Y`
	@touch checkreleasedate.temp ; for f in $^ ; do ! grep -H "\\Provides[a-zA-Z]*{.*}\[[0-9]" $$f | grep -v \\[`git log -1 --format=%cd --date=format:%Y/%m/%d $$f` || ( echo "  Should be `git log -1 --format=%cd --date=format:%Y/%m/%d $$f`" && rm -f checkreleasedate.temp ) ; done ; ( test -e checkreleasedate.temp && rm checkreleasedate.temp )

nocheckreleasedate:

zip: versiondir nocheckexternalization checksums checkreleasedate \
	README LICENCE $(ins) $(dtx) $(sty) $(tex) $(other) $(pdf) 
	@echo Copying files to the version `cat VERSION` directory ...
	@cp README LICENCE $(ins) $(dtx) $(doc-nonderived-sty) $(package-nonderived-sty) $(tex) $(pdf) $(other) versions/`cat VERSION`/forest
	@echo Zipping files
	@cd versions/`cat VERSION` && zip -r forest.zip forest
	@cd ../..
	@echo ZIP file: versions/`cat VERSION`/forest.zip

zipforce: versiondirremove zip

runtime: VERSION $(package-sty)
	mkdir -p runtime
	mkdir runtime/`cat VERSION`
	cp $(package-sty) runtime/`cat VERSION`
	chmod -w runtime/`cat VERSION`/*
	zip runtime/forest-runtime_v`cat VERSION`.zip $(package-sty)

runtimedirremove:
	@if [[ -d runtime && -d runtime/`cat VERSION` ]] ; then read -p "Remove runtime files for forest v`cat VERSION` (y/n)? " jane ; if [ "$$jane" = "y" ] ; then rm -r runtime/`cat VERSION` runtime/forest-runtime_v`cat VERSION`.zip ; echo Removed it! ; else echo "Ok, I won't!" ; exit 1; fi ; fi

runtimeforce: runtimedirremove runtime

currentruntime:
	@mkdir -p runtime/current
	@ln -sfr $(package-sty) runtime/current

v=current
use: currentruntime
	echo Trying to switch to forest v$(v) ...
	@if ! [[ -d runtime/$(v) && -f runtime/$(v)/forest.sty ]] ; then echo Runtimes files for forest v$(v) don\'t exist! Available versions: `ls runtime | grep -v zip`; false ; fi
	@if [[ ! -h $(HOME)/texmf/tex/latex/forest ]] ; then echo Something is wrong with directory $(HOME)/texmf/tex/latex/forest ... it should be a symlink to some version\'s runtime directory. ; false ; fi
	ln -sfT $(abspath runtime/$(v)) $(HOME)/texmf/tex/latex/forest
	@texhash 2> /dev/null

used:
	@ls -l $(HOME)/texmf/tex/latex/forest | sed -e 's/.*\///;'
	@echo Available versions: `ls runtime | grep -v zip`

clean-aux: 
	rm *.{aux,log,auxlock,bbl,blg,synctex.gz,idx,ilg,ind,out,toc,foridx,memo,memo.tmp}
clean-test: 
	rm test-*.{aux,log,auxlock,bbl,blg,synctex.gz,idx,ilg,ind,ins,out,toc} test-*~
