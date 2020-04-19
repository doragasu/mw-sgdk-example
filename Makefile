# This makefile has been modified from the original from SGDK, to suit my
# Linux build environment. Please edit the path of the tools to suit your
# environment

PREFIX=m68k-elf-
GDK=$(HOME)/src/github/SGDK
TOOLBIN=/opt/toolchains/gen/bin
LIB= $(GDK)/lib

LIBSRC= $(GDK)/src
LIBRES= $(GDK)/res
LIBINCLUDE= $(GDK)/inc

SRC= src
RES= res
INCLUDE= inc

SHELL= bash
RM= rm
CP= cp
CC= $(PREFIX)gcc
LD= $(PREFIX)ld
NM= $(PREFIX)nm
JAVA= java
ECHO= echo
OBJCPY= $(PREFIX)objcopy
ASMZ80= $(TOOLBIN)/sjasm
MACCER= $(BIN)/mac68k
SIZEBND= $(TOOLBIN)/sizebnd
BINTOS= $(TOOLBIN)/bintos
RESCOMP= $(JAVA) -jar $(TOOLBIN)/rescomp.jar
MKDIR= mkdir

SRC_C= $(wildcard *.c)
SRC_C+= $(wildcard $(SRC)/*.c)
# Add MegaWiFi sources
SRC_C+= $(wildcard $(SRC)/mw/*.c)
SRC_S= $(wildcard *.s)
SRC_S+= $(wildcard $(SRC)/*.s)
SRC_ASM= $(wildcard *.asm)
SRC_ASM+= $(wildcard $(SRC)/*.asm)
SRC_S80= $(wildcard *.s80)
SRC_S80+= $(wildcard $(SRC)/*.s80)

RES_C= $(wildcard $(RES)/*.c)
RES_S= $(wildcard $(RES)/*.s)
RES_RES= $(wildcard *.res)
RES_RES+= $(wildcard $(RES)/*.res)

OBJ= $(RES_RES:.res=.o)
OBJ+= $(RES_S:.s=.o)
OBJ+= $(RES_C:.c=.o)
OBJ+= $(SRC_S80:.s80=.o)
OBJ+= $(SRC_ASM:.asm=.o)
OBJ+= $(SRC_S:.s=.o)
OBJ+= $(SRC_C:.c=.o)
OBJS= $(addprefix out/, $(OBJ))

LST= $(SRC_C:.c=.lst)
LSTS= $(addprefix out/, $(LST))

INCS= -I$(INCLUDE) -I$(SRC) -I$(SRC)/mw -I$(RES) -I$(LIBINCLUDE) -I$(LIBRES)
DEFAULT_FLAGS= -m68000 -Wall -Wextra -Wno-shift-negative-value $(INCS) -DENABLE_NEWLIB=1 
FLAGSZ80= -i$(SRC) -i$(INCLUDE) -i$(RES) -i$(LIBSRC) -i$(LIBINCLUDE)


#release: FLAGS= $(DEFAULT_FLAGS) -O1 -fomit-frame-pointer -flto -ffat-lto-objects
release: FLAGS= $(DEFAULT_FLAGS) -O3 -fuse-linker-plugin -fno-web -fno-gcse -fno-unit-at-a-time -fomit-frame-pointer -flto -ffat-lto-objects
release: LIBMD= $(LIB)/libmd.a
release: pre-build out/rom.bin out/symbol.txt

debug: FLAGS= $(DEFAULT_FLAGS) -O1 -ggdb -DDEBUG=1
debug: LIBMD= $(LIB)/libmd_debug.a
debug: pre-build out/rom.bin out/rom.out out/symbol.txt

asm: FLAGS= $(DEFAULT_FLAGS) -O3 -fuse-linker-plugin -fno-web -fno-gcse -fno-unit-at-a-time -fomit-frame-pointer -S
asm: pre-build $(LSTS)


all: release
default: release

Default: release
Debug: debug
Release: release
Asm: asm

.PHONY: clean

cleanlst:
	$(RM) -f $(LSTS)

cleanobj:
	$(RM) -f $(OBJS) out/sega.o out/rom_head.bin out/rom_head.o out/rom.out

clean: cleanobj cleanlst
	$(RM) -f out.lst out/cmd_ out/rom.nm out/rom.wch out/rom.bin

cleanrelease: clean

cleandebug: clean
	$(RM) -f out/symbol.txt

cleanasm: cleanlst

cleandefault: clean
cleanDefault: clean

cleanRelease: cleanrelease
cleanDebug: cleandebug
cleanAsm: cleanasm

pre-build:
	$(MKDIR) -p $(SRC)/boot
	$(MKDIR) -p out
	$(MKDIR) -p out/src
	$(MKDIR) -p out/res
	$(MKDIR) -p out/src/mw


out/rom.bin: out/rom.out
	$(OBJCPY) -O binary out/rom.out out/rom.bin
	$(SIZEBND) out/rom.bin -sizealign 131072

out/symbol.txt: out/rom.out
	$(NM) -n out/rom.out > out/symbol.txt

out/rom.out: out/sega.o out/cmd_ $(LIBMD)
	$(CC) -n -T mw.ld out/sega.o @out/cmd_ $(LIBMD) $(LIB)/libgcc.a -o out/rom.out
	$(RM) out/cmd_

out/cmd_: $(OBJS)
	$(ECHO) "$(OBJS)" > out/cmd_

out/sega.o: $(SRC)/boot/sega.s out/rom_head.bin
	$(CC) $(DEFAULT_FLAGS) -c $(SRC)/boot/sega.s -o $@

out/rom_head.bin: out/rom_head.o
	$(OBJCPY) -O binary $< $@
#	$(LD) -T mw.ld -oformat binary -o $@ $<

out/rom_head.o: $(SRC)/boot/rom_head.c
	$(CC) $(DEFAULT_FLAGS) -c $< -o $@

$(SRC)/boot/sega.s: $(LIBSRC)/boot/sega.s
	$(CP) $< $@

$(SRC)/boot/rom_head.c: $(LIBSRC)/boot/rom_head.c
	$(CP) $< $@


out/%.lst: %.c
	$(CC) $(FLAGS) -c $< -o $@

out/%.o: %.c
	$(CC) $(FLAGS) -c $< -o $@

out/%.o: %.s
	$(CC) $(FLAGS) -c $< -o $@

%.s: %.res
	$(RESCOMP) $< $@

%.s: %.asm
	$(MACCER) -o $@ $<

%.o80: %.s80
	$(ASMZ80) $(FLAGSZ80) $< $@ out.lst

%.s: %.o80
	$(BINTOS) $<
