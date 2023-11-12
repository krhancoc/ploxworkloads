CC = clang
CFLAGS_EXTRA = -Wall -fPIC
LDFLAGS += -shared -lthr

SOURCES = coverage.c
OBJECTS = $(SOURCES:.c=.o)
LIBRARY = libcoverage.so

all: $(LIBRARY)

$(LIBRARY): $(SOURCES)
	$(CC) $(SOURCES) $(CFLAGS) $(CFLAGS_EXTRA) -o $(LIBRARY) $(LDFLAGS) 

clean:
	rm -f $(OBJECTS) $(LIBRARY)

.PHONY: clean
