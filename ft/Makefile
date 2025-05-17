CC := gcc
CFLAGS := -Wall -Werror -I../../..
LDFLAGS := -L./build -lftd2xx -Wl,-rpath,'$$ORIGIN/build'

TARGET := load_and_flash_eeprom
SRCS := load_and_flash_eeprom.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRCS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

clean:
	rm -f $(TARGET)

