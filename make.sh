#!/bin/bash -e

TARGET='memset_explicit'
QEMU_BIN="${TARGET}-qemu-flash.bin"
QEMU_BIN_SIZE=4096

if [[ "$1" != "xgcc" && \
  "$1" != "x86" && \
  "$1" != "arm64" && \
  "$1" != "armv7" && \
  "$1" != "armv7s" ]]
then
  echo "[-] $(basename $0) {xgcc, x86, armv7, armv7s, arm64}"
  exit
fi

if [[ "$1" == xgcc ]]
then
  PATH=${PATH}:"/$(pwd)/bin"
  TOOLCHAIN_LIBDIR1="/$(pwd)/arm-none-eabi/lib"
  TOOLCHAIN_LIBDIR2="/$(pwd)/lib/gcc/arm-none-eabi/4.9.3"
  COMPILER='gcc'
  TOOLCHAIN_PREFIX='arm-none-eabi-'
  TOOLCHAIN_CFLAGS='-ggdb -D__EMBEDDED__ --specs nosys.specs -O3 -mtune=cortex-m4 -fno-builtin -mfpu=vfp'
  TOOLCHAIN_LDFLAGS="-L${TOOLCHAIN_LIBDIR1} -L${TOOLCHAIN_LIBDIR2} -lc -lg -lgcc --entry main -Ttext=0x00"
fi

if [[ "$1" == "arm64" || "$1" == "armv7" || "$1" == "armv7s" ]]
then
  COMPILER='clang'
  TOOLCHAIN_PREFIX="xcrun -sdk iphoneos "
  TOOLCHAIN_CFLAGS="-ggdb -O3 -fno-builtin -arch $1"
  TOOLCHAIN_LDFLAGS="-iphoneos_version_min 7.0 -lSystem -arch $1"
fi

if [[ "$1" == "x86" ]]
then
  COMPILER='gcc'
  TOOLCHAIN_PREFIX=''
  TOOLCHAIN_CFLAGS='-ggdb -O3 -fno-builtin -arch i386'
  TOOLCHAIN_LDFLAGS='-macosx_version_min 10.9 -lSystem'
fi

if [[ "$1" == "clean" ]]
then
  rmtrash *.{dSYM,bin,elf,o,s}
  exit
fi

echo "[+] compiling ${TARGET}.c ..."
if [[ "$1" == "arm64" || "$1" == "armv7" || "$1" == "armv7s" ]]
then
  ${TOOLCHAIN_PREFIX}${COMPILER} ${TOOLCHAIN_CFLAGS} -o ${TARGET}.elf ${TARGET}.c
else
  ${TOOLCHAIN_PREFIX}${COMPILER} ${TOOLCHAIN_CFLAGS} -S ${TARGET}.c
  ${TOOLCHAIN_PREFIX}${COMPILER} ${TOOLCHAIN_CFLAGS} -c ${TARGET}.c
fi

if [[ "$1" == 'xgcc' || "$1" == 'x86' ]]
then
  echo "[+] linking ${TARGET}.o ..."
  ${TOOLCHAIN_PREFIX}ld ${TOOLCHAIN_LDFLAGS} ${TARGET}.o -o ${TARGET}.elf
fi

if [[ "$1" == "xgcc" ]]
then
  echo "[+] extracting binary from ${TARGET}.elf ..."
  ${TOOLCHAIN_PREFIX}objcopy \
    -O binary \
    ${TARGET}.elf \
    ${TARGET}.bin

  echo "[+] creating qemu image ..."
  dd if=/dev/zero of=${QEMU_BIN} bs=${QEMU_BIN_SIZE} count=${QEMU_BIN_SIZE}
  dd if=${TARGET}.bin of=${QEMU_BIN} bs=4096 conv=notrunc
fi

if [[ $? -eq 0 ]]
then
  echo "disas ${TARGET}" | ${TOOLCHAIN_PREFIX}gdb -x - ${TARGET}.elf \
    2>/dev/null | sed -n "/Dump of assembler/,/End of assembler/p"
  echo 'disas main' | ${TOOLCHAIN_PREFIX}gdb -x - ${TARGET}.elf \
    2>/dev/null | sed -n "/Dump of assembler/,/End of assembler/p"
  # qemu-system-arm -M connex -pflash memset_explicit-qemu-flash.bin -gdb tcp::1234 -S
fi

