#!/bin/bash

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

# Check autobuild is around or fail
if [ -z "$AUTOBUILD" ] ; then
    fail
fi

if [ "$OSTYPE" = "cygwin" ] ; then
    export AUTOBUILD="$(cygpath -u $AUTOBUILD)"
fi

# Load autobuild provided shell functions and variables
set +x
eval "$("$AUTOBUILD" source_environment)"
set -x

top="$(dirname "$0")"
stage="$(pwd)"

pushd "$top/libidn"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            echo "Windows is not supported yet"
            fail
        ;;
        "darwin")
            make clean
            sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk/
            opts="${TARGET_OPTS:--arch i386 -arch x86_64 -iwithsysroot $sdk -mmacosx-version-min=10.6}" 
            CC="clang" CFLAGS="$opts" CXXFLAGS="$opts" LDFLAGS="$opts" \
                ./configure --prefix="$stage"
            make
            make install

            mkdir -p "$stage/include/idn"
            mv "$stage"/include/*.h "$stage/include/idn/"
        ;;
        "linux")
            echo "Linux is not supported yet"
            fail
        ;;
    esac

    mkdir -p "$stage/LICENSES"
    cp "COPYING.LESSERv2" "$stage/LICENSES/libidn.txt"
popd
pass
