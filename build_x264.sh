#!/bin/sh

if [ -d x264 ]; then
  cd x264
else
  git clone git://git.videolan.org/x264.git
  cd x264
fi

git reset --hard
git clean -f -d
git checkout master

X264_PREFIX=$ROOT_DIR/build/android/x264
rm -rf $X264_PREFIX && mkdir -p $X264_PREFIX

./configure --prefix=$X264_PREFIX \
   --enable-static \
   --enable-pic \
   --disable-asm \
   --disable-cli \
   --host=arm-linux \
   --cross-prefix=$TOOLCHAIN/bin/arm-linux-androideabi- \
   --sysroot=$SYSROOT

cp config.* $X264_PREFIX
make clean
make -j4 || exit 1
make install || exit 1
make clean && make distclean || exit 0

cd ..
