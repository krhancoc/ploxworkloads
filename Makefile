CC = clang
SUBDIRS := lighttpd-1.4.72
REQGMAKE := wrk libmemcached-1.0.18
GOBUILD := dbbench-0.6.10

all: $(SUBDIRS) $(REQGMAKE) $(GOBUILD)

.PHONY: all $(SUBDIRS) $(REQGMAKE) $(GOBUILD)

configure:
	cd lighttpd-1.4.72; ./configure
	cd libmemcached-1.0.18; ./configure --enable-memaslap

distclean:
	$(MAKE) -C lighttpd-1.4.72 distclean


$(SUBDIRS):
	$(MAKE) -C $@ CC=$(CC)

$(REQGMAKE):
	gmake -C $@ CC=$(CC)

$(GOBUILD):
	cd dbbench-0.6.10; go mod download
	cd dbbench-0.6.10; go build -v ./cmd/dbbench/... 


clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done 
	@for dir in $(REQGMAKE); do \
		gmake -C $$dir clean; \
	done
