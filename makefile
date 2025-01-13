.SUFFIXES: .tex .pdf .view

DOCS = xmatch
STILTS = stilts

DATA = points.fits pairs.fits pairs1.fits pairs2.fits
FIGS = match1.pdf match2.pdf match3.pdf match4.pdf

PDFLATEX = env TEXINPUTS=:/mbt/local/share/texslides pdflatex

build: $(DOCS:=.pdf) $(DATA)

xmatch.pdf: $(FIGS)

view: xmatch.view

data: $(DATA)

points.fits:
	$(STILTS) tpipe \
                  in=:skysim:1000000 \
                  cmd='select abs(dec)<1&&ra>273&&ra<278' \
                  out=$@

RADIUS=80

pairs1.fits: points.fits
	$(STILTS) tmatch1 progress=none runner=sequential \
                  matcher=sky params=$(RADIUS) action=wide2 \
                  in=points.fits values='ra dec' \
                  out=$@

pairs2.fits: points.fits
	$(STILTS) tmatch2 progress=none runner=sequential \
                  matcher=sky params=$(RADIUS) find=all join=1and2 \
                  in1=points.fits in2=points.fits \
                  values1='ra dec' values2='ra dec' \
                  scorecol=dist ocmd='select dist>0' \
                  out=$@

pairs.fits: pairs2.fits
	ln -s pairs2.fits $@

PLOT1=$(STILTS) plot2sky \
      shading=flat legend=false sex=false labelpos=none scalebar=false \
      clon=275.35 clat=0 radius=0.6 xpix=600 ypix=400 crowd=1.5 \
      in_1=points.fits lon_1=ra lat_1=dec \
      layer_1a=mark size_1a=2 \
      layer_1b=skyellipse ra_1b=$(RADIUS) unit_1b=arcsec \
      in_3=pairs.fits color_3=black \
      lon1_3=ra_1 lat1_3=dec_1 lon2_3=ra_2 lat2_3=dec_2 \
      layer_3x=link2 thick_3x=1 \
      lon_31=ra_1 lat_31=dec_1 \
      layer_31a=mark size_31a=2 \
      layer_31b=skyellipse ra_31b=$(RADIUS) unit_31b=arcsec \
      lon_32=ra_2 lat_32=dec_2 \
      layer_32a=mark size_32a=2 \
      layer_32b=skyellipse ra_32b=$(RADIUS) unit_32b=arcsec \

match1.pdf: points.fits pairs.fits
	$(PLOT1) grid=false \
                 seq=_1a,_1b \
                 out=$@

match2.pdf: points.fits pairs.fits
	$(PLOT1) grid=false \
                 seq=_1a,_1b,_31a,_31b,_32a,_32b,_3x \
                 out=$@

match3.pdf: points.fits pairs.fits
	$(PLOT1) grid=true \
                 seq=_1a,_1b \
                 out=$@

match4.pdf: points.fits pairs.fits
	$(PLOT1) grid=true \
                 seq=_1a,_1b,_31a,_31b,_32a,_32b,_3x \
                 out=$@


                 

clean:
	rm -f $(DATA) $(FIGS)
	rm -f $(DOCS:=.aux) $(DOCS:=.log) $(DOCS:=.out) $(DOCS:=.pdf)

.tex.pdf:
	$(PDFLATEX) $< && \
        $(PDFLATEX) $< || \
        rm -f $@

.pdf.view:
	test -f $< && \
        okular $< 2>/dev/null


