CC = clang
SUBDIRS := libcoverage lighttpd-1.4.72
REQGMAKE := wrk

all: $(SUBDIRS) $(REQGMAKE)

.PHONY: all $(SUBDIRS) $(REQGMAKE)

configure:
	cd lighttpd-1.4.72; autoreconf -f
	cd lighttpd-1.4.72; ./configure

distclean:
	$(MAKE) -C lighttpd-1.4.72 distclean


$(SUBDIRS):
	$(MAKE) -C $@ CC=$(CC)

$(REQGMAKE):
	gmake -C $@ CC=$(CC)

clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done 
	@for dir in $(REQGMAKE); do \
		gmake -C $$dir clean; \
	done
