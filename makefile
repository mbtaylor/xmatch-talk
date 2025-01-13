.SUFFIXES: .tex .pdf .view

DOCS = xmatch
DATA =

PDFLATEX = env TEXINPUTS=:/mbt/local/share/texslides pdflatex

build: $(DOCS:=.pdf) $(DATA)

view: xmatch.view

data: $(DATA)

clean:
	rm -f $(DOCS:=.aux) $(DOCS:=.log) $(DOCS:=.out) $(DOCS:=.pdf)
	rm -f messier.csv astro.sqlite

.tex.pdf:
	$(PDFLATEX) $< && \
        $(PDFLATEX) $< || \
        rm -f $@

.pdf.view:
	test -f $< && \
        okular $< 2>/dev/null


