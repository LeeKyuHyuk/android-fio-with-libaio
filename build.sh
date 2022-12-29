#!/bin/bash
#
# Example build script
# Optional parameteres below:
set -o nounset
set -o errexit

export LC_ALL=POSIX
export PARALLEL_JOBS=`cat /proc/cpuinfo | grep cores | wc -l`
export WORKSPACE_DIR=$PWD
# End of optional parameters

function step() {
  echo -e "\e[7m\e[1m>>> $1\e[0m"
}

function success() {
  echo -e "\e[1m\e[32m$1\e[0m"
}

function extract() {
  case $1 in
    *.zip) unzip $1 -d $2 ;;
    *.tgz) tar -zxf $1 -C $2 ;;
    *.tar.gz) tar -zxf $1 -C $2 ;;
    *.tar.bz2) tar -jxf $1 -C $2 ;;
    *.tar.xz) tar -Jxf $1 -C $2 ;;
  esac
}

function timer {
  if [[ $# -eq 0 ]]; then
    echo $(date '+%s')
  else
    local stime=$1
    etime=$(date '+%s')
    if [[ -z "$stime" ]]; then stime=$etime; fi
    dt=$((etime - stime))
    ds=$((dt % 60))
    dm=$(((dt / 60) % 60))
    dh=$((dt / 3600))
    printf '%02d:%02d:%02d' $dh $dm $ds
  fi
}

total_build_time=$(timer)

step "fio 3.33"
rm -rf $WORKSPACE_DIR/fio $WORKSPACE_DIR/fio-fio-3.33
extract $WORKSPACE_DIR/fio-3.33.tar.gz $WORKSPACE_DIR
( cd $WORKSPACE_DIR/fio-fio-3.33 && \
    NAME=Android \
    CROSS_COMPILE="$WORKSPACE_DIR/android-ndk-r24/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android31-" \
    CC="$WORKSPACE_DIR/android-ndk-r24/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android31-clang" \
    libaio=yes \
    ./configure )
make -j1 LIBS="-Wl,-Bstatic -laio  -Wl,-Bdynamic -landroid -lm -ldl -lz" -C $WORKSPACE_DIR/fio-fio-3.33
cp -v $WORKSPACE_DIR/fio-fio-3.33/fio $WORKSPACE_DIR/fio
file $WORKSPACE_DIR/fio
rm -rf $WORKSPACE_DIR/fio-fio-3.33

success "\nTotal build time: $(timer $total_build_time)\n"