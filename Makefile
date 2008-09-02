#
# Makefile for LaTeX document with figures

TEXES:=$(wildcard *.tex)
TEXINCS:=$(wildcard *.texinc)
TOCS:=$(patsubst %.tex,%.toc,$(TEXES))
DVIS:=$(patsubst %.tex,%.dvi,$(TEXES))
PDFS:=$(patsubst %.tex,%.pdf,$(TEXES))
PSES:=$(patsubst %.tex,%.ps,$(TEXES))
AUXES:=$(patsubst %.tex,%.aux,$(TEXES))
BBLS:=$(patsubst %.tex,%.bbl,$(TEXES))
BLGS:=$(patsubst %.tex,%.blg,$(TEXES))
LOGS:=$(patsubst %.tex,%.log,$(TEXES))

BIBS:=$(wildcard *.bib)

FIGURES:=$(wildcard *.fig)
FIGBAKS:=$(patsubst %.fig,%.fig.bak,$(FIGURES))
PSTEXES:=$(patsubst %.fig,%.pstex,$(FIGURES))
PSTEX_TS:=$(patsubst %.fig,%.pstex_t,$(FIGURES))

all: $(PSES)

ps: $(PSES)

publish: $(PDFS)
	@if (svn status | grep "^M");\
	then \
		echo "Please commit changes to Subversion before publication"; \
		false; \
	else \
		echo "Copying to public_html"; \
		cp $(PDFS) $(HOME)/public_html/; \
	fi

distclean: clean
	rm -f $(PDFS) $(PSES)

clean:
	rm -f $(PSTEXES) $(PSTEX_TS) $(AUXES) $(BBLS) $(BLGS) $(DVIS) $(LOGS) \
		$(FIGBAKS) $(TOCS) margins

%.pstex: %.fig
	fig2dev -L pstex -F $< $@

%.pstex_t: %.fig
	fig2dev -L pstex_t -F -p `echo "$@" | sed -e "s/\.pstex_t$$/\.pstex/"` $< $@

# This is necessary to stop the inbuilt rule for running TeX from taking over.
%.dvi: %.tex

%.dvi: %.tex $(BIBS) $(PSTEX_TS) $(PSTEXES) $(TEXINCS) margins
	latex $< && \
	if (grep `echo "$@" | sed -e "s/\.dvi$$/\.log/"` -e "Citation.*undefined"); \
	then \
		bibtex `echo "$@" | sed -e "s/\.dvi$$//"` && \
		latex $<; \
	else \
		for bib in $(BIBS); \
		do \
			if [ `echo "$@" | sed -e "s/\.dvi$$/\.bbl/"` -ot $$bib ]; \
			then \
				bibtex `echo "$@" | sed -e "s/\.dvi$$//"` && \
				latex $< && \
				break; \
			fi; \
		done; \
	fi && \
	if (grep `echo "$@" | sed -e "s/\.dvi$$/\.log/"` -e "Rerun"); \
	then \
		latex $<; \
	fi


%.ps: %.dvi $(PSTEXES)
ifeq ($(PRINTABLE),0)
ifdef BOUNDING_BOX
	dvips -Ppdf $< -o $@ && \
	sed -i "s/^%%BoundingBox: .*$$/%%BoundingBox: $(BOUNDING_BOX)/" $@
else
	dvips -Ppdf $< -o $@ && \
	sed -i "s/^%%BoundingBox: .*$$/%%BoundingBox: 110 186 729 675/" $@
endif
else
	dvips -Ppdf $< -o $@
endif

%.pdf: %.ps
	ps2pdf $< $@

.PRECIOUS: $(PSTEXES) $(PSTEX_TS) $(DVIS)

margins: fix-margins
ifeq ($(PRINTABLE),0)
	./fix-margins
else
	echo > margins
endif
