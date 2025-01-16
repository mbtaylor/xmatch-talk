.SUFFIXES: .tex .pdf .view

DOCS = xmatch
VCS_STAMP = gitid.tex
STILTS = java -jar $(STILTS_JAR)
STILTS_JAR = stilts.jar

DATA_DIR = data
MATCH_DATA = $(DATA_DIR)/plei-gaia.fits $(DATA_DIR)/plei-2mass.fits \
             $(DATA_DIR)/ngc346-gouliermis.fits $(DATA_DIR)/ngc346-gaia.fits
PLEI_GEOM = CIRCLE(56.75, 24.1166, 3)

FIG_DATA = t0.fits t1.fits pairs.fits
FIGS = match1.pdf match2.pdf match3.pdf match4.pdf

PDFLATEX = env TEXINPUTS=:/mbt/local/share/texslides pdflatex

build: $(DOCS:=.pdf) $(FIG_DATA) $(MATCH_DATA)

matchdata: $(MATCH_DATA)

xmatch.pdf: $(FIGS) $(VCS_STAMP)

view: xmatch.view

$(STILTS_JAR):
	curl -OL http://www.starlink.ac.uk/stilts/stilts.jar

SkyLib.class: SkyLib.java $(STILTS_JAR)
	javac -classpath $(STILTS_JAR) SkyLib.java

t0.fits: $(STILTS_JAR)
	$(STILTS) tpipe \
                  in=:skysim:1000000 \
                  cmd='select abs(b)<0.5&&abs(l-44.2)<0.5' \
                  out=$@

t1.fits: $(STILTS_JAR) t0.fits SkyLib.class
	java -Djel.classes=SkyLib -classpath $(STILTS_JAR):. \
                  uk.ac.starlink.ttools.Stilts \
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

pairs.fits: $(STILTS_JAR) t0.fits t1.fits
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

match1.pdf: $(STILTS_JAR) t0.fits t1.fits pairs.fits
	$(PLOT1) grid=false \
                 seq=_1a,_1b,_2a,_2b \
                 out=$@

match2.pdf: $(STILTS_JAR) t0.fits t1.fits pairs.fits
	$(PLOT1) grid=false \
                 seq=_1a,_1b,_2a,_2b,_31a,_31b,_32a,_32b,_3x \
                 out=$@

match3.pdf: $(STILTS_JAR) t0.fits t1.fits pairs.fits
	$(PLOT1) grid=true \
                 seq=_1a,_1b,_2a,_2b \
                 out=$@

match4.pdf: $(STILTS_JAR) t0.fits t1.fits pairs.fits
	$(PLOT1) grid=true \
                 seq=_1a,_1b,_2a,_2b,_31a,_31b,_32a,_32b,_3x \
                 out=$@

$(DATA_DIR):
	mkdir -p $(DATA_DIR)

$(DATA_DIR)/plei-gaia.fits: $(DATA_DIR) $(STILTS_JAR)
	$(STILTS) tapquery tapurl=http://dc.g-vo.org/tap sync=true \
               adql="WITH reg AS ( \
                       SELECT ra, dec, ra_error, dec_error, \
                              pmra, pmdec, pmra_error, pmdec_error, \
                              parallax, parallax_error, \
                              radial_velocity, radial_velocity_error, \
                              phot_g_mean_mag, \
                              phot_bp_mean_mag, phot_rp_mean_mag, \
                              phot_bp_mean_mag-phot_rp_mean_mag AS bp_rp \
                       FROM gaia.edr3lite \
                       WHERE 1=CONTAINS(POINT(ra, dec), $(PLEI_GEOM)) \
                     ) \
                     SELECT * FROM reg \
                     WHERE SQRT(POWER((pmra - 19.7)/2.7, 2) \
                              + POWER((pmdec + 45.3)/3.1, 2)) < 1" \
               out=$@

$(DATA_DIR)/plei-2mass.fits: $(DATA_DIR) $(STILTS_JAR)
	$(STILTS) tapquery tapurl=http://dc.g-vo.org/tap sync=true \
               adql="SELECT RAJ2000, DEJ2000, errMaj, errMin, errPA, \
                            mainId, Jmag, Hmag, Kmag \
                     FROM twomass.data \
                     WHERE 1=CONTAINS(POINT(RAJ2000,DEJ2000), $(PLEI_GEOM))" \
               maxrec=500000 out=$@

$(DATA_DIR)/ngc346-gouliermis.fits: $(DATA_DIR) $(STILTS_JAR)
	$(STILTS) tpipe \
               in='http://vizier.u-strasbg.fr/viz-bin/votable?-source=J%2fApJS%2f166%2f549&-oc.form=dec&-out.meta=Dhul&-c=14.771207+-72.1759&-c.rd=1.0&-out.add=_RAJ%2C_DEJ%2C_r&-out.max=100000' \
               out=$@

$(DATA_DIR)/ngc346-gaia.fits: $(DATA_DIR) $(STILTS_JAR)
	$(STILTS) cone \
               serviceurl='https://gaia.ari.uni-heidelberg.de/cone/search?' \
               lon=14.771207 lat=-72.1759 radius=0.05 verb=1 \
               out=$@

$(VCS_STAMP):
	echo -n '{\\tt ' >$@
	pwd | sed 's%.*/%%' >>$@
	echo -n '{\\jobname}.tex ' >>$@
	echo -n `git log -1 --pretty="format:%h %ci" | sed "s/ [+-].*//"`>>$@
	echo '}' >>$@

clean:
	rm -f SkyLib.class
	rm -f $(FIG_DATA) $(FIGS) $(VCS_STAMP)
	rm -f $(DOCS:=.aux) $(DOCS:=.log) $(DOCS:=.out) $(DOCS:=.pdf)

veryclean: clean
	rm -f $(STILTS_JAR)
	rm -rf $(DATA_DIR)

.tex.pdf:
	$(PDFLATEX) $< && \
        $(PDFLATEX) $< || \
        rm -f $@

.pdf.view:
	test -f $< && \
        okular $< 2>/dev/null


