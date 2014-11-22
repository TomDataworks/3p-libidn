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
            sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.9.sdk/
            opts="${TARGET_OPTS:--arch i386 -arch x86_64 -iwithsysroot $sdk -mmacosx-version-min=10.7}" 
            CC="clang" CFLAGS="$opts -g" CXXFLAGS="$opts -g" LDFLAGS="$opts -g" \
                ./configure --prefix="$stage" --libdir="$stage/lib/debug" \
                --includedir="$stage/include/idn"
            make
            make install

            make distclean

            CC="clang" CFLAGS="$opts -O2" CXXFLAGS="$opts -O2" LDFLAGS="$opts -O3" \
                ./configure --prefix="$stage" --libdir="$stage/lib/release" \
                --includedir="$stage/include/idn"
            make
            make install

			make distclean

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
