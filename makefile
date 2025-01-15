.SUFFIXES: .tex .pdf .view

DOCS = xmatch
VCS_STAMP = gitid.tex
STILTS = stilts

DATA = t0.fits t1.fits pairs.fits
FIGS = match1.pdf match2.pdf match3.pdf match4.pdf

PDFLATEX = env TEXINPUTS=:/mbt/local/share/texslides pdflatex
PAL_JAR = /mbt/starjava/lib/pal/pal.jar

build: $(DOCS:=.pdf) $(DATA)

xmatch.pdf: $(FIGS) $(VCS_STAMP)

view: xmatch.view

data: $(DATA)

SkyLib.class: SkyLib.java $(PAL_JAR)
	javac -classpath $(PAL_JAR) SkyLib.java

t0.fits:
	$(STILTS) tpipe \
                  in=:skysim:1000000 \
                  cmd='select abs(b)<0.5&&abs(l-44.2)<0.5' \
                  out=$@

t1.fits: t0.fits SkyLib.class
	$(STILTS) -Djel.classes=SkyLib -classpath . \
                  tpipe \
                  in=t0.fits \
                  cmd='addcol pos1 randomShiftFlat(ra,dec,120./3600.)' \
                  cmd='replacecol ra pos1[0]' \
                  cmd='replacecol dec pos1[1]' \
                  cmd='delcols pos1' \
                  cmd='select abs(b)<0.5&&abs(l-44.2)<0.5' \
                  cmd='every 3' \
                  out=$@

RADIUS=60

pairs.fits: t0.fits t1.fits
	$(STILTS) tmatch2 progress=none runner=sequential \
                  matcher=sky params=$(RADIUS) \
                  in1=t0.fits values1='ra dec' \
                  in2=t1.fits values2='ra dec' \
                  out=$@

PLOT1=$(STILTS) plot2sky \
      shading=flat legend=false sex=false labelpos=none scalebar=false \
      datasys=equatorial viewsys=galactic \
      clon=44.455 clat=0.225 radius=0.17 xpix=600 ypix=400 crowd=2 \
      in_1=t0.fits lon_1=ra lat_1=dec color_1=red \
      layer_1a=mark size_1a=2 \
      layer_1b=skyellipse ra_1b=0.5*$(RADIUS) unit_1b=arcsec \
      in_2=t1.fits lon_2=ra lat_2=dec color_2=blue \
      layer_2a=mark size_2a=2 \
      layer_2b=skyellipse ra_2b=0.5*$(RADIUS) unit_2b=arcsec \
      in_3=pairs.fits color_3=black \
      lon1_3=ra_1 lat1_3=dec_1 lon2_3=ra_2 lat2_3=dec_2 \
      layer_3x=link2 thick_3x=1 \
      lon_31=ra_1 lat_31=dec_1 \
      layer_31a=mark size_31a=2 \
      layer_31b=skyellipse ra_31b=0.5*$(RADIUS) unit_31b=arcsec \
      lon_32=ra_2 lat_32=dec_2 \
      layer_32a=mark size_32a=2 \
      layer_32b=skyellipse ra_32b=0.5*$(RADIUS) unit_32b=arcsec \

match1.pdf: t0.fits t1.fits pairs.fits
	$(PLOT1) grid=false \
                 seq=_1a,_1b,_2a,_2b \
                 out=$@

match2.pdf: t0.fits t1.fits pairs.fits
	$(PLOT1) grid=false \
                 seq=_1a,_1b,_2a,_2b,_31a,_31b,_32a,_32b,_3x \
                 out=$@

match3.pdf: t0.fits t1.fits pairs.fits
	$(PLOT1) grid=true \
                 seq=_1a,_1b,_2a,_2b \
                 out=$@

match4.pdf: t0.fits t1.fits pairs.fits
	$(PLOT1) grid=true \
                 seq=_1a,_1b,_2a,_2b,_31a,_31b,_32a,_32b,_3x \
                 out=$@

$(VCS_STAMP):
	echo -n '{\\tt ' >$@
	pwd | sed 's%.*/%%' >>$@
	echo -n '{\\jobname}.tex ' >>$@
	echo -n `git log -1 --pretty="format:%h %ci" | sed "s/ [+-].*//"`>>$@
	echo '}' >>$@

clean:
	rm -f SkyLib.class
	rm -f $(DATA) $(FIGS) $(VCS_STAMP)
	rm -f $(DOCS:=.aux) $(DOCS:=.log) $(DOCS:=.out) $(DOCS:=.pdf)

.tex.pdf:
	$(PDFLATEX) $< && \
        $(PDFLATEX) $< || \
        rm -f $@

.pdf.view:
	test -f $< && \
        okular $< 2>/dev/null


