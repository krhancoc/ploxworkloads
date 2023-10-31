CC = clang
CFLAGS = -Wall -fPIC
LDFLAGS = -shared -lthr

SOURCES = coverage.c
OBJECTS = $(SOURCES:.c=.o)
LIBRARY = libcoverage.so

all: $(LIBRARY)

$(LIBRARY): $(SOURCES)
	$(CC) $(SOURCES) $(CFLAGS) -o $(LIBRARY) $(LDFLAGS) 

clean:
	rm -f $(OBJECTS) $(LIBRARY)

.PHONY: clean
