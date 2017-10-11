VERSION=0.0.1

SPMINER_VERSION:=$(shell git describe 2>/dev/null || echo '$(VERSION)')
VERSION_H := $(shell cat version.h 2>/dev/null)
ifneq ($(lastword $(VERSION_H)),"$(SPMINER_VERSION)")
$(info $(shell echo '     GEN      'version.h))
$(shell echo '#define SPMINER_VERSION "$(SPMINER_VERSION)"' > version.h)
endif

OS = linux

CC = gcc
CFLAGS = -O2 -finline-functions -fno-strict-aliasing -g
CFLAGS += -Wall -Wwrite-strings
LDFLAGS += -g
LD = gcc
AR = ar

ALL_CFLAGS = $(CFLAGS) $(BASIC_CFLAGS)

GCC_BASE = $(shell $(CC) --print-file-name=)
BASIC_CFLAGS = -DGCC_BASE=\"$(GCC_BASE)\"

MULTIARCH_TRIPLET = $(shell $(CC) -print-multiarch 2>/dev/null)
BASIC_CFLAGS += -DMULTIARCH_TRIPLET=\"$(MULTIARCH_TRIPLET)\"

ifeq ($(HAVE_GCC_DEP),yes)
BASIC_CFLAGS += -Wp,-MD,$(@D)/.$(@F).d
endif

DESTDIR=
PREFIX=/usr
BINDIR=$(PREFIX)/bin
LIBDIR=$(PREFIX)/lib
MANDIR=$(PREFIX)/share/man
MAN1DIR=$(MANDIR)/man1
INCLUDEDIR=$(PREFIX)/include

PROGRAMS=spminer
INST_PROGRAMS=spminer

LIB_H=    token.h parse.h lib.h symbol.h expression.h

LIB_OBJS= parse.o tokenize.o symbol.o lib.o \
	  expression.o

LIB_FILE= libspminer.a
SLIB_FILE= libspminer.so

LIBS=$(LIB_FILE)

#
# Pretty print
#
V	      = @
Q	      = $(V:1=)
QUIET_CC      = $(Q:@=@echo    '     CC       '$@;)
QUIET_AR      = $(Q:@=@echo    '     AR       '$@;)
QUIET_GEN     = $(Q:@=@echo    '     GEN      '$@;)
QUIET_LINK    = $(Q:@=@echo    '     LINK     '$@;)
# We rely on the -v switch of install to print 'file -> $install_dir/file'
QUIET_INST_SH = $(Q:@=echo -n  '     INSTALL  ';)
QUIET_INST    = $(Q:@=@echo -n '     INSTALL  ';)

define INSTALL_EXEC
	$(QUIET_INST)install -v $1 $(DESTDIR)$2/$1 || exit 1;

endef

define INSTALL_FILE
	$(QUIET_INST)install -v -m 644 $1 $(DESTDIR)$2/$1 || exit 1;

endef

SED_PC_CMD = 's|@version@|$(VERSION)|g;		\
	      s|@prefix@|$(PREFIX)|g;		\
	      s|@libdir@|$(LIBDIR)|g;		\
	      s|@includedir@|$(INCLUDEDIR)|g'

# Allow users to override build settings without dirtying their trees
-include local.mk


all: $(PROGRAMS)

all-installable: $(INST_PROGRAMS) $(LIBS) $(LIB_H)

install: all-installable

$(foreach p,$(PROGRAMS),$(eval $(p): $($(p)_EXTRA_DEPS) $(LIBS)))
$(PROGRAMS): % : %.o 
	$(QUIET_LINK)$(LD) $(LDFLAGS) -o $@ $^ $($@_EXTRA_OBJS)

$(LIB_FILE): $(LIB_OBJS)
	$(QUIET_AR)$(AR) rcs $@ $(LIB_OBJS)

$(SLIB_FILE): $(LIB_OBJS)
	$(QUIET_LINK)$(CC) $(LDFLAGS) -Wl,-soname,$@ -shared -o $@ $(LIB_OBJS)

DEP_FILES := $(wildcard .*.o.d)
$(if $(DEP_FILES),$(eval include $(DEP_FILES)))

%.o: %.c
	$(QUIET_CC)$(CC) -o $@ -c $(ALL_CFLAGS) $<
