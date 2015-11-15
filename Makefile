INTERACTION = batchmode
SINGLEPASS = no
EXTERNALIZE = yes

ins = forest.ins forest-doc.ins
dtx = $(shell grep -Poh '\\from{(.*?)}' $(ins) | sed 's/\\from{\(.*\)}/\1/;' | sort | uniq)

package-sty = $(shell grep -Poh '\\file{(.*?)}' $(ins) | sed 's/\\file{\(.*\)}/\1/;') \
	forest-compat.sty
package-tex = 
package-other =
package-pdf = forest.pdf

doc-tex = forest-doc.tex
doc-sty = forest-doc.sty
doc-other = forest-doc.ist
doc-pdf = forest-doc.pdf

tex = $(package-tex) $(doc-tex)
sty = $(package-sty) $(doc-sty)
other = $(package-other) $(doc-other)
pdf = $(package-pdf) $(doc-pdf)

%.success: % ;

forest-doc.pdf: forest-doc.tex.success $(dtx) $(doc-sty) $(doc-other)
	$(call externalize, $(<:.success=))
	@echo
	@echo Pass 1 ...
	$(call compile, $(<:.success=))
ifneq ($(SINGLEPASS),yes)
	@echo
	@echo Pass 2 ...
	$(call compile, $(<:.success=))
	@echo
	@echo Pass 3 ...
	$(call compile, $(<:.success=))
endif
	@echo Compilation successful!
	@touch -r $< $<.success

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

compile = pdflatex -synctex=1 -interaction $(INTERACTION) $(1) && \
	( bibtex $(basename $1) || ( echo bibtex failed! && true ) ) && \
	( if [[ -f $(basename $1).idx ]] ; then makeindex -s forest-doc.ist $(basename $1) ; fi || ( echo makeindex failed! && true ) ) && \
	cp $(basename $1).pdf $(basename $1).bak.pdf

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
	mkdir versions/`cat VERSION`
	mkdir versions/`cat VERSION`/forest

versiondirremove: VERSION
	@if [[ -d versions && -d versions/`cat VERSION` ]] ; then read -p "Remove forest v`cat VERSION` (y/n)? " jane ; if [ "$$jane" = "y" ] ; then rm -r versions/`cat VERSION` ; echo Removed it! ; else echo "Ok, I won't!" ; exit 1; fi ; fi

forest%.dtx.checksum: forest%.dtx
	@cat $< | tr -cd '\\' |wc -m > $@
	@sed -ne '1 s/^% *\\CheckSum{\([0-9\]*\)\} *$$/\1/p;' $< | \
		if ! diff $@ - >/dev/null ; then \
			checksum=`cat $@` ; \
			echo Fixing checksum in $< to $$checksum ; \
			sed -ie "1 s/\\CheckSum{\([0-9]*\)}/\\CheckSum{$$checksum}/;" forest.dtx ; \
		fi


checkexternalization :
	@echo Checking if externalization is off ...
	@if grep '^[^%]\\tikzexternalize$$' forest-doc.tex >/dev/null || [[ "$(EXTERNALIZE)" == 'yes' ]] ; then echo ; echo Switch off externalization! ; echo; exit 1; fi

zip: versiondir checkexternalization $(patsubst %.dtx,%.dtx.checksum,$(dtx)) \
	README LICENCE $(ins) $(dtx) $(sty) $(tex) $(pdf) $(other)
	@echo Copying files to the version `cat VERSION` directory ...
	@cp README LICENCE $(ins) $(dtx) $(sty) $(tex) $(pdf) $(other) versions/`cat VERSION`/forest
	@echo Zipping files
	@cd versions/`cat VERSION` && zip -r forest.zip forest
	@cd ../..
	@echo ZIP file: versions/`cat VERSION`/forest.zip

zipforce: versiondirremove zip

clean-aux: 
	rm *.{aux,log,auxlock,bbl,blg,synctex.gz,idx,ilg,ind,out,toc,foridx}
clean-test: 
	rm test-*.{aux,log,auxlock,bbl,blg,synctex.gz,idx,ilg,ind,ins,out,toc} test-*~
