#
# This file is part of RGBDS.
#
# Copyright (c) 1997-2018, Carsten Sorensen and RGBDS contributors.
#
# SPDX-License-Identifier: MIT
#

.SUFFIXES:
.SUFFIXES: .h .y .c .o

# User-defined variables

Q		:= @
PREFIX		:= /usr/local
bindir		:= ${PREFIX}/bin
mandir		:= ${PREFIX}/share/man
STRIP		:= -s
BINMODE		:= 755
MANMODE		:= 644
CHECKPATCH	:= ../linux/scripts/checkpatch.pl

# Other variables

PKG_CONFIG	:= pkg-config
PNGCFLAGS	:= `${PKG_CONFIG} --cflags libpng`
PNGLDFLAGS	:= `${PKG_CONFIG} --libs-only-L libpng`
PNGLDLIBS	:= `${PKG_CONFIG} --libs-only-l libpng`

# Note: if this comes up empty, `version.c` will automatically fall back to last release number
VERSION_STRING	:= `git describe --tags --dirty --always 2>/dev/null`

WARNFLAGS	:= -Wall

# Overridable CFLAGS
CFLAGS		?= -O3 -DNDEBUG
# Non-overridable CFLAGS
REALCFLAGS	:= ${CFLAGS} ${WARNFLAGS} -std=gnu11 -D_POSIX_C_SOURCE=200809L \
		   -Iinclude
# Overridable LDFLAGS
LDFLAGS		?=
# Non-overridable LDFLAGS
REALLDFLAGS	:= ${LDFLAGS} ${WARNFLAGS} \
		   -DBUILD_VERSION_STRING=\"${VERSION_STRING}\"

YFLAGS		?=

BISON		:= bison
RM		:= rm -rf

# Rules to build the RGBDS binaries

all: rgbasm rgblink rgbfix rgbgfx

rgbasm_obj := \
	src/asm/charmap.o \
	src/asm/fstack.o \
	src/asm/lexer.o \
	src/asm/macro.o \
	src/asm/main.o \
	src/asm/math.o \
	src/asm/parser.o \
	src/asm/output.o \
	src/asm/rpn.o \
	src/asm/section.o \
	src/asm/symbol.o \
	src/asm/util.o \
	src/asm/warning.o \
	src/extern/err.o \
	src/extern/getopt.o \
	src/extern/utf8decoder.o \
	src/hashmap.o \
	src/linkdefs.o

src/asm/lexer.o src/asm/main.o: src/asm/parser.h

rgblink_obj := \
	src/link/assign.o \
	src/link/main.o \
	src/link/object.o \
	src/link/output.o \
	src/link/patch.o \
	src/link/script.o \
	src/link/section.o \
	src/link/symbol.o \
	src/extern/err.o \
	src/extern/getopt.o \
	src/hashmap.o \
	src/linkdefs.o

rgbfix_obj := \
	src/fix/main.o \
	src/extern/err.o \
	src/extern/getopt.o

rgbgfx_obj := \
	src/gfx/gb.o \
	src/gfx/main.o \
	src/gfx/makepng.o \
	src/extern/err.o \
	src/extern/getopt.o

rgbasm: ${rgbasm_obj}
	$Q${CC} ${REALLDFLAGS} -o $@ ${rgbasm_obj} ${REALCFLAGS} src/version.c -lm

rgblink: ${rgblink_obj}
	$Q${CC} ${REALLDFLAGS} -o $@ ${rgblink_obj} ${REALCFLAGS} src/version.c

rgbfix: ${rgbfix_obj}
	$Q${CC} ${REALLDFLAGS} -o $@ ${rgbfix_obj} ${REALCFLAGS} src/version.c

rgbgfx: ${rgbgfx_obj}
	$Q${CC} ${REALLDFLAGS} ${PNGLDFLAGS} -o $@ ${rgbgfx_obj} ${REALCFLAGS} src/version.c ${PNGLDLIBS}

# Rules to process files

# We want the Bison invocation to pass through our rules, not default ones
.y.o:

# Bison-generated C files have an accompanying header
src/asm/parser.h: src/asm/parser.c
	$Qtouch $@

src/asm/parser.c: src/asm/parser.y
	$QDEFS=; \
	add_flag(){ \
		if src/check_bison_ver.sh $$1 $$2; then \
			DEFS+=-D$$3; \
		fi \
	}; \
	add_flag 3 5 api.token.raw=true; \
	${BISON} -d $$DEFS ${YFLAGS} -o $@ $<

.c.o:
	$Q${CC} ${REALCFLAGS} ${PNGCFLAGS} -c -o $@ $<

# Target used to remove all files generated by other Makefile targets

clean:
	$Q${RM} rgbasm rgbasm.exe
	$Q${RM} rgblink rgblink.exe
	$Q${RM} rgbfix rgbfix.exe
	$Q${RM} rgbgfx rgbgfx.exe
	$Qfind src/ -name "*.o" -exec rm {} \;
	$Q${RM} rgbshim.sh
	$Q${RM} src/asm/parser.c src/asm/parser.h

# Target used to install the binaries and man pages.

install: all
	$Qmkdir -p ${DESTDIR}${bindir}
	$Qinstall ${STRIP} -m ${BINMODE} rgbasm ${DESTDIR}${bindir}/rgbasm
	$Qinstall ${STRIP} -m ${BINMODE} rgbfix ${DESTDIR}${bindir}/rgbfix
	$Qinstall ${STRIP} -m ${BINMODE} rgblink ${DESTDIR}${bindir}/rgblink
	$Qinstall ${STRIP} -m ${BINMODE} rgbgfx ${DESTDIR}${bindir}/rgbgfx
	$Qmkdir -p ${DESTDIR}${mandir}/man1 ${DESTDIR}${mandir}/man5 ${DESTDIR}${mandir}/man7
	$Qinstall -m ${MANMODE} src/rgbds.7 ${DESTDIR}${mandir}/man7/rgbds.7
	$Qinstall -m ${MANMODE} src/gbz80.7 ${DESTDIR}${mandir}/man7/gbz80.7
	$Qinstall -m ${MANMODE} src/rgbds.5 ${DESTDIR}${mandir}/man5/rgbds.5
	$Qinstall -m ${MANMODE} src/asm/rgbasm.1 ${DESTDIR}${mandir}/man1/rgbasm.1
	$Qinstall -m ${MANMODE} src/asm/rgbasm.5 ${DESTDIR}${mandir}/man5/rgbasm.5
	$Qinstall -m ${MANMODE} src/fix/rgbfix.1 ${DESTDIR}${mandir}/man1/rgbfix.1
	$Qinstall -m ${MANMODE} src/link/rgblink.1 ${DESTDIR}${mandir}/man1/rgblink.1
	$Qinstall -m ${MANMODE} src/link/rgblink.5 ${DESTDIR}${mandir}/man5/rgblink.5
	$Qinstall -m ${MANMODE} src/gfx/rgbgfx.1 ${DESTDIR}${mandir}/man1/rgbgfx.1

# Target used to check the coding style of the whole codebase.
# `extern/` is excluded, as it contains external code that should not be patched
# to meet our coding style, so applying upstream patches is easier.
# `.y` files aren't checked, unfortunately...

checkcodebase:
	$Qfor file in `git ls-files | grep -E '(\.c|\.h)$$' | grep -Ev '(src|include)/extern/'`; do	\
		${CHECKPATCH} -f "$$file";					\
	done

# Target used to check the coding style of the patches from the upstream branch
# to the HEAD. Runs checkpatch once for each commit between the current HEAD and
# the first common commit between the HEAD and origin/master.
# `.y` files aren't checked, unfortunately...

BASE_REF:= origin/master
checkpatch:
	$Qeval COMMON_COMMIT=$$(git merge-base HEAD ${BASE_REF});	\
	for commit in `git rev-list $$COMMON_COMMIT..HEAD`; do		\
		echo "[*] Analyzing commit '$$commit'";			\
		git format-patch --stdout "$$commit~..$$commit"		\
			-- src include '!src/extern' '!include/extern'	\
			| ${CHECKPATCH} - || true;			\
	done

# This target is used during development in order to prevent adding new issues
# to the source code. All warnings are treated as errors in order to block the
# compilation and make the continous integration infrastructure return failure.

develop:
	$Qenv $(MAKE) -j WARNFLAGS="-Werror -Wall -Wextra -Wpedantic -Wno-type-limits \
		-Wno-sign-compare -Wvla -Wformat -Wformat-security -Wformat-overflow=2 \
		-Wformat-truncation=1 -Wformat-y2k -Wswitch-enum -Wunused \
		-Wuninitialized -Wunknown-pragmas -Wstrict-overflow=5 \
		-Wstringop-overflow=4 -Walloc-zero -Wduplicated-cond \
		-Wfloat-equal -Wshadow -Wcast-qual -Wcast-align -Wlogical-op \
		-Wnested-externs -Wno-aggressive-loop-optimizations -Winline \
		-Wundef -Wstrict-prototypes -Wold-style-definition \
		-fsanitize=shift -fsanitize=integer-divide-by-zero \
		-fsanitize=unreachable -fsanitize=vla-bound \
		-fsanitize=signed-integer-overflow -fsanitize=bounds \
		-fsanitize=object-size -fsanitize=bool -fsanitize=enum \
		-fsanitize=alignment -fsanitize=null" CFLAGS="-ggdb3 -O0"

# Targets for the project maintainer to easily create Windows exes.
# This is not for Windows users!
# If you're building on Windows with Cygwin or Mingw, just follow the Unix
# install instructions instead.

mingw32:
	$Qmake CC=i686-w64-mingw32-gcc BISON=bison \
		PKG_CONFIG=i686-w64-mingw32-pkg-config -j

mingw64:
	$Qmake CC=x86_64-w64-mingw32-gcc BISON=bison \
		PKG_CONFIG=x86_64-w64-mingw32-pkg-config -j

wine-shim:
	$Qecho '#!/bin/bash' > rgbshim.sh
	$Qecho 'WINEDEBUG=-all wine $$0.exe "$${@:1}"' >> rgbshim.sh
	$Qchmod +x rgbshim.sh
	$Qln -s rgbshim.sh rgbasm
	$Qln -s rgbshim.sh rgblink
	$Qln -s rgbshim.sh rgbfix
	$Qln -s rgbshim.sh rgbgfx

# Target for the project maintainer to produce distributable release tarballs
# of the source code.

dist:
	$Qgit ls-files | sed s~^~$${PWD##*/}/~ \
	  | tar -czf rgbds-`git describe --tags | cut -c 2-`.tar.gz -C .. -T -
