TARGETS = ieee whitepaper

$(TARGETS):
	R -e 'library("knitr"); knit("$@.Rnw")'
	pdflatex $@.tex
	pdflatex $@.tex

clean:
	rm -rf {ieee,whitepaper}.{aux,log,pdf,tex,toc} figure
