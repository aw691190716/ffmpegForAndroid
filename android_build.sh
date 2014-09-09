#!/bin/sh

API_VERSION=android-9
TARGET_ARCH=arm
NDK_TOOLCHAIN_VERSION=4.6

HOST_OS=$(echo $(uname -a) | tr '[A-Z]' '[a-z]')
HOST=linux
OS=x86

if echo $HOST_OS | grep -q "cygwin"; then
  HOST=windows
  if [ x"$NDK" = "x" ]; then
    NDK="D:/ProgramFiles/android-ndk-r9b"
  fi
  DIR=${PWD/\/cygdrive\//}
  ROOT_DIR=$(echo ${DIR%%/*} | tr '[a-z]' '[A-Z]'):/${DIR#*/}
else
  if [ x"$NDK" = "x" ]; then
    NDK=$HOME/tools/android-ndk-r9b
  fi
  ROOT_DIR=$PWD
fi
if echo $HOST_OS | grep -q "x86_64"; then
  OS=x86_64
fi

export ROOT_DIR
export SYSROOT=$NDK/platforms/$API_VERSION/arch-$TARGET_ARCH/
export TOOLCHAIN=$NDK/toolchains/arm-linux-androideabi-$NDK_TOOLCHAIN_VERSION/prebuilt/$HOST-$OS

export CC="ccache $TOOLCHAIN/bin/arm-linux-androideabi-gcc"
export LD=$TOOLCHAIN/bin/arm-linux-androideabi-ld
export AR=$TOOLCHAIN/bin/arm-linux-androideabi-ar
export CPP=$TOOLCHAIN/bin/arm-linux-androideabi-cpp
export CXX=$TOOLCHAIN/bin/arm-linux-androideabi-g++
export AS=$TOOLCHAIN/bin/arm-linux-androideabi-as
export RANLIB=$TOOLCHAIN/bin/arm-linux-androideabi-ranlib
export TMPDIR=$ROOT_DIR/build

rm -rf $ROOT_DIR/build/android

if [ ! -d ffmpeg ]; then
  git clone git://source.ffmpeg.org/ffmpeg.git ffmpeg
fi
if [ -d ffmpeg ]; then
  cd ffmpeg
  git reset --hard
  git clean -f -d
  git checkout master
  if [ x"$1" = "xupdate" ]; then
    git pull
  fi
else
  exit 0
fi

CFLAGS="-O3 -Wall -mthumb -pipe -fpic -fasm -marm \
  -finline-limit=300 -ffast-math \
  -fstrict-aliasing -Werror=strict-aliasing \
  -fmodulo-sched -fmodulo-sched-allow-regmoves \
  -Wno-psabi -Wa,--noexecstack \
  -D__ARM_ARCH_5__ -D__ARM_ARCH_5T__ -D__ARM_ARCH_5E__ -D__ARM_ARCH_5TE__ \
  -I$SYSROOT/usr/include \
  -DHAVE_SYS_UIO_H=1 -Dipv6mr_interface=ipv6mr_ifindex -fno-strict-aliasing \
  -DANDROID -DNDEBUG -I$NDK/sources/cxx-stl/system/include"

#  --enable-small \
#  --enable-gpl \
#  --enable-nonfree \
#  --enable-protocol=file \
#  --disable-network \
#  --disable-yasm \
#  --disable-protocols \
#  --disable-swresample \
#  --disable-avresample \
#  --disable-postproc "

FFMPEG_FLAGS="--target-os=linux \
  --arch=$TARGET_ARCH \
  --enable-cross-compile \
  --sysroot=$SYSROOT \
  --cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
  --cc=$TOOLCHAIN/bin/arm-linux-androideabi-gcc \
  --nm=$TOOLCHAIN/bin/arm-linux-androideabi-nm \
  --enable-static \
  --disable-symver \
  --disable-doc \
  --disable-ffplay \
  --disable-ffmpeg \
  --disable-ffprobe \
  --disable-ffserver \
  --disable-avdevice \
  --disable-avfilter \
  --disable-encoders \
  --disable-muxers \
  --disable-bsfs \
  --disable-filters \
  --disable-devices \
  --disable-everything \
  --enable-protocols  \
  --enable-parsers \
  --enable-demuxers \
  --disable-demuxer=sbg \
  --enable-decoders \
  --enable-network \
  --enable-swscale  \
  --enable-swscale-alpha \
  --enable-asm \
  --extra-libs=-lgcc \
  --enable-version3"

LDFLAGS=""

for version in armv7a-neon armv7a armv6vfp armv5te armv4t; do

  case $version in
    armv7a-neon)
      CPU="armv7-a"
      EXTRA_FLAGS="--enable-neon"
      EXTRA_CFLAGS="-march=armv7-a -mfpu=neon -mfloat-abi=softfp -mvectorize-with-neon-quad"
      EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
      EXTRA_OBJS="libavcodec/neon/*.o"
      ;;
    armv7a)
      CPU="armv7-a"
      EXTRA_FLAGS=""
      EXTRA_CFLAGS="-march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp"
      EXTRA_LDFLAGS="-Wl,--fix-cortex-a8"
      EXTRA_OBJS=""
      ;;
    armv6vfp)
      CPU="armv6"
      EXTRA_FLAGS=""
      EXTRA_CFLAGS="-march=armv6 -mfpu=vfp -mfloat-abi=softfp -DCMP_HAVE_VFP"
      EXTRA_LDFLAGS=""
      EXTRA_OBJS=""
      ;;
    armv5te)
      CPU="armv5te"
      EXTRA_FLAGS=""
      EXTRA_CFLAGS="-march=armv5te -mtune=xscale"
      EXTRA_LDFLAGS=""
      EXTRA_OBJS=""
      ;;
    armv4t)
      CPU="armv4t"
      EXTRA_FLAGS=""
      EXTRA_CFLAGS="-march=armv4t -mtune=arm920t -D__ARM_ARCH_4T__"
      EXTRA_LDFLAGS=""
      EXTRA_OBJS=""
      ;;
    *)
      CPU=""
      EXTRA_FLAGS=""
      EXTRA_CFLAGS=""
      EXTRA_LDFLAGS=""
      EXTRA_OBJS=""
      ;;
  esac

  PREFIX="$ROOT_DIR/build/android/$version" && mkdir -p $PREFIX
  FFMPEG_FLAGS="$FFMPEG_FLAGS --prefix=$PREFIX"

  ./configure $FFMPEG_FLAGS --cpu=$CPU $EXTRA_FLAGS --extra-cflags="$CFLAGS $EXTRA_CFLAGS" --extra-ldflags="$LDFLAGS $EXTRA_LDFLAGS" --extra-cxxflags='-Wno-multichar -fno-exceptions -fno-rtti' | tee $PREFIX/configuration.txt

  if [ x"$HOST" = "xwindows" ]; then
    cat config.h | \
    sed '/^\#define CC_IDENT/N; s/\r//' | \
    cat > config.h.tmp
    mv config.h config.h.bak
    mv config.h.tmp config.h
    cat config.mak | \
    sed '/^CC_IDENT/N; s/\r//' | \
    cat > config.mak.tmp
    mv config.mak config.mak.bak
    mv config.mak.tmp config.mak
  fi
  cp config.* $PREFIX

#  break
  make clean
  make -j4 || exit 1
  make install || exit 1

  for file in libavcodec/log2_tab.o libavformat/log2_tab.o libavformat/golomb_tab.o libswresample/log2_tab.o libswscale/log2_tab.o; do
    if [ -f $file ]; then
      rm $file
    fi
  done
#  rm libavcodec/log2_tab.o libavformat/log2_tab.o libavformat/golomb_tab.o libswresample/log2_tab.o libswscale/log2_tab.o

  $CC -llog -lc -ldl -lm -lz -shared --sysroot=$SYSROOT -Wl,--no-undefined -Wl,-z,noexecstack $LDFLAGS $EXTRA_LDFLAGS compat/*.o libavutil/*.o libavutil/arm/*.o libavcodec/*.o libavcodec/arm/*.o $EXTRA_OBJS libswresample/*.o libswresample/arm/*.o libavformat/*.o libswscale/*.o -o $PREFIX/libffmpeg.so
  cp $PREFIX/libffmpeg.so $PREFIX/libffmpeg-debug.so
  $TOOLCHAIN/bin/arm-linux-androideabi-strip --strip-unneeded $PREFIX/libffmpeg.so

  make clean && make distclean || exit 0
#  break

done
cd ..
