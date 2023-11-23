CC = gcc
CFLAGS = -Wall -Wextra

TARGET = sec

all: $(TARGET)

$(TARGET): sec.c
	$(CC) $(CFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)

.PHONY: all clean
