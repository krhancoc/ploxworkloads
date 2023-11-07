CC = clang
SUBDIRS := libcoverage lighttpd-1.4.72
REQGMAKE := wrk libmemcached-1.0.18

all: $(SUBDIRS) $(REQGMAKE)

.PHONY: all $(SUBDIRS) $(REQGMAKE)

configure:
	cd lighttpd-1.4.72; autoreconf -f
	cd lighttpd-1.4.72; ./configure
	cd libmemcached-1.0.18; ./configure --enable-memaslap

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
