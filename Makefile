# User can override these variables as needed:
CC = g++
LD = $(CC)
CFLAGS = -O3 -ffast-math -ftree-vectorize -msse3 -Wall -Wno-multichar
LDFLAGS =
ARCH =
INC = /opt/local/include /opt/local/include/SDL
LIBDIR = /usr/lib64
LIB = libSDLmain.a libSDL_image.so libSDL.so
DEF =
EXE = heightmapper
MAC_FRAMEWORKS = OpenGL Cocoa AudioUnit AudioToolbox IOKit Carbon
MAC_MFLAGS = -fobjc-direct-dispatch


CARCH =
LDARCH =
INCLUDES = $(INC)
LIBRARIES = $(foreach lib,$(LIB),$(LIBDIR)/$(lib))
SOURCES = $(wildcard *.cpp)
OBJECTS = $(patsubst %.cpp,%.o,$(patsubst %.m,%.o,$(SOURCES)))
EXE_INSTALL = $(EXE)
BINDIR = $(GAMEDIR)


UNAME = $(shell uname)
ifeq ($(UNAME), Darwin)
# Begin Mac OS X section.

ifndef ARCH
# Unless ARCH is defined, Macs should make 32-bit universal binaries by default.
ARCH = ppc i386
endif

# Use MacPorts lib directory.
LIBDIR = /opt/local/lib

# Macs must pad install names so install_name_tool can make them longer.
LDFLAGS += -headerpad_max_install_names

# Always suggest 10.4 Tiger as the minimum Mac OS X version.
CFLAGS += -mmacosx-version-min=10.4
LDFLAGS += -mmacosx-version-min=10.4

ifeq (,$(findstring x86_64,$(ARCH)))
# When building without x86_64 target, use the 10.4 Tiger universal SDK and ppc/i386 MacPorts libs.
CFLAGS += -isysroot /Developer/SDKs/MacOSX10.4u.sdk
LDFLAGS += -isysroot /Developer/SDKs/MacOSX10.4u.sdk
LIBDIR="/Developer/SDKs/MacOSX10.4u.sdk/opt/local/lib"
endif

KERNEL_VERSION = $(shell uname -r)
ifneq (8.11.0,$(KERNEL_VERSION))
ifneq (x86_64,$(ARCH))
# When building on 10.5+ with any non-x86_64 target, use Apple gcc 4.0.
CC = /Developer/usr/bin/g++-4.0
CFLAGS += -fno-stack-protector
LDFLAGS += -fno-stack-protector
endif
endif

# Override LIB specified above for Linux.
LIB = libSDL_image.a libSDL.a libSDLmain.a libpng.a libtiff.a libXrandr.a libXrender.a libXext.a libX11.a libxcb.a libXdmcp.a libXau.a libjpeg.a libbz2.a liblzma.a libz.a

# Macs don't have .so files, so replace with .a files.
LIBRARIES := $(patsubst %.so,%.a,$(LIBRARIES))

# Add frameworks to Mac linker line.
LIBRARIES += $(foreach framework,$(MAC_FRAMEWORKS),-framework $(framework))

# End Mac OS X section.
endif


ifdef ARCH
# Add compiler/linker flags for arch.
CARCH = $(foreach arch,$(ARCH),-arch $(arch))
LDARCH = $(foreach arch,$(ARCH),-arch $(arch))
endif


default: $(SOURCES) $(EXE)

$(EXE): $(OBJECTS)
	$(LD) $(LDFLAGS) $(LDARCH) $(OBJECTS) $(LIBRARIES) -o $@

.cpp.o:
	$(CC) -c $(CFLAGS) $(CARCH) $(foreach inc,$(INCLUDES),-I$(inc)) $(foreach def,$(DEF),-D$(def)) $< -o $@

.m.o:
	$(CC) -c $(CFLAGS) $(MAC_MFLAGS) $(CARCH) $(foreach inc,$(INCLUDES),-I$(inc)) $< -o $@

objects: $(SOURCES) $(OBJECTS)

clean:
	rm -rf *.o "$(EXE)" "$(EXE)"_*

ppc:
	make objects ARCH="ppc"
	make ARCH="ppc" EXE="$(EXE)_ppc"

i32:
	make objects ARCH="i386"
	make ARCH="i386" EXE="$(EXE)_i32"

i64:
	make objects ARCH="x86_64" CC="/opt/local/bin/g++"
	make ARCH="x86_64" EXE="$(EXE)_i64" CC="/opt/local/bin/g++"

universal:
	make clean
	make i64 EXE="$(EXE)"
	make clean
	make ppc EXE="$(EXE)"
	make clean
	make i32 EXE="$(EXE)"
	make lipo

lipo: $(EXE)_ppc $(EXE)_i32 $(EXE)_i64
	lipo $(EXE)_ppc $(EXE)_i32 $(EXE)_i64 -create -output $(EXE)
