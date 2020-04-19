# MegaWiFi API example compiled for SGDK

This project is a modification of my [MegaWiFi API example](https://github.com/doragasu/mw-api), in order for it to build agains the popular [SGDK development kit](https://github.com/Stephane-D/SGDK). Go to the API example repository to get more information, and to browse the MegaWiFi API.

# Instructions

## Getting the toolchain

You will need a m68k cross compiler with C standard library support. The most popular choice to fulfill these requirements, is GCC compiled against newlib. If you are an Archlinux (or derivative such as Manjaro) user, you can try my PKGBUILDs. You need to install (in this order) `m68k-elf-binutils`, `m68k-elf-gcc-bootstrap`, `m68k-elf-newlib` and finally `m68k-elf-gcc`. I have also a PKGBUILD for `m68k-elf-gdb` in case you need it. If you have another Linux distro, you will have to search in its package manager, or build it yourself. I might try adding instructions here when I get the time.

I will also try adding here a prebuilt toolchain for Windows, when I get the time.

## Building SGDK library

Once you have your toolchain ready, clone SGDK and edit `inc/config.h`. Change the line:

```
#define ENABLE_NEWLIB       0
```

To

```
#define ENABLE_NEWLIB       1
```

Then edit the file `makelib.gen` and point the paths to your newlib enabled compiler (do not use the one that comes with SGDK, it does not have newlib).

## Building the ROM

Go to this project, and edit `Makefile`. Change the paths for them to point yo your tools installation (including the newlib enabled compiler). Then `make` the project. If everything goes OK, you should have the project built under `out/rom.bin`.

# Limitations

SGDK is not the most "external library friendly" development kit out there. Some improvements are being done in this direction, e.g. by enabling compilation against newlib. But it is not yet perfect. For example SGDK has a `string.h` file, so when you do a `#include <string.h>`, you end up including the one in SGDK instead of the newlib one. And as the prototypes for the functions already in newlib have been excluded from the SGDK `string.h` file, this causes a bunch of implicit declaration warnings. I might try sorting out these problems in the future, but until then, you will get a bunch of warnings when compiling and linking.

Another problem is that SGDK redefines some standard types such as `int8_t`. To workaround this problem you need to `#include <stding.h>` before including any other SGDK header.

