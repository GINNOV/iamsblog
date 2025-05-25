# Makefile for send2adf - Apple Silicon compatible
CC = gcc
CFLAGS = -Wall -Wextra -O2 -std=c99
TARGET = send2adf
SOURCE = send2adf.c

# Detect architecture and set appropriate flags
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_M),arm64)
    # Apple Silicon specific flags
    CFLAGS += -arch arm64
    LDFLAGS += -arch arm64
endif

# ADFLib paths - adjust these based on your installation
ADFLIB_DIR = ./adflib
ADFLIB_INCLUDE = $(ADFLIB_DIR)/src
ADFLIB_LIB = $(ADFLIB_DIR)/src/.libs/libadf.a

# Include and library flags
INCLUDES = -I$(ADFLIB_INCLUDE)
LIBS = $(ADFLIB_LIB)

.PHONY: all clean install adflib

all: adflib $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) $(INCLUDES) -o $(TARGET) $(SOURCE) $(LIBS) $(LDFLAGS)

adflib:
	@echo "Building ADFLib..."
	@if [ ! -d "$(ADFLIB_DIR)" ]; then \
		echo "Cloning ADFLib repository..."; \
		git clone https://github.com/lclevy/ADFlib.git adflib; \
	fi
	@cd $(ADFLIB_DIR) && \
	if [ ! -f "configure" ]; then \
		echo "Running autoreconf..."; \
		autoreconf -fiv; \
	fi && \
	if [ ! -f "Makefile" ]; then \
		echo "Configuring ADFLib..."; \
		./configure --enable-static --disable-shared; \
	fi && \
	echo "Compiling ADFLib..." && \
	$(MAKE)

install: $(TARGET)
	cp $(TARGET) /usr/local/bin/

clean:
	rm -f $(TARGET)

clean-all: clean
	rm -rf $(ADFLIB_DIR)

help:
	@echo "send2adf Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Build the send2adf tool (default)"
	@echo "  adflib    - Download and build ADFLib dependency"
	@echo "  install   - Install send2adf to /usr/local/bin"
	@echo "  clean     - Remove built files"
	@echo "  clean-all - Remove built files and ADFLib source"
	@echo "  help      - Show this help message"
	@echo ""
	@echo "Usage example:"
	@echo "  make"
	@echo "  ./send2adf input1.bin input2.txt output.adf VolumeName"