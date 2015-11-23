#!/bin/bash

# turn on verbose debugging output for parabuild logs.
set -x
# make errors fatal
set -e

IDN_VERSION="1.31"

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

echo "${IDN_VERSION}" > "${stage}/VERSION.txt"

pushd "$top/libidn"
    case "$AUTOBUILD_PLATFORM" in
        "windows")
            echo "Windows is not supported yet"
            fail
        ;;
        "darwin")
            sdk=/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX10.11.sdk/
            opts="${TARGET_OPTS:--arch i386 -arch x86_64 -iwithsysroot $sdk -mmacosx-version-min=10.8}" 
            CC="clang" CFLAGS="$opts -g" CXXFLAGS="$opts -g" LDFLAGS="$opts -g" \
                ./configure --prefix="$stage" --libdir="$stage/lib/debug" \
                --includedir="$stage/include/idn"
            make
            make install

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make check
            fi

            make distclean

            CC="clang" CFLAGS="$opts -O2" CXXFLAGS="$opts -O2" LDFLAGS="$opts -O3" \
                ./configure --prefix="$stage" --libdir="$stage/lib/release" \
                --includedir="$stage/include/idn"
            make
            make install

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make check
            fi

            make distclean

        ;;
        "linux")
            #This is literally black magic.
            touch configure.ac aclocal.m4 configure Makefile.am Makefile.in

            opts="${TARGET_OPTS:--m32}" 
            CFLAGS="$opts -g" CXXFLAGS="$opts -g" LDFLAGS="$opts -g" \
                ./configure --prefix="\${AUTOBUILD_PACKAGES_DIR}" --libdir="\${prefix}/lib/debug" --includedir="\${prefix}/include/idn"
            make
            make install DESTDIR="$stage"

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make check
            fi

            make distclean

            CFLAGS="$opts -O2" CXXFLAGS="$opts -O2" LDFLAGS="$opts -O2" \
                ./configure --prefix="\${AUTOBUILD_PACKAGES_DIR}" --libdir="\${prefix}/lib/release" --includedir="\${prefix}/include/idn"
            make
            make install DESTDIR="$stage"

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make check
            fi

            make distclean
        ;;
        "linux64")
            #This is literally black magic.
            touch configure.ac aclocal.m4 configure Makefile.am Makefile.in

            opts="${TARGET_OPTS:--m64}" 
            CFLAGS="$opts -Og -g" CXXFLAGS="$opts -Og -g" LDFLAGS="$opts -g" \
                ./configure --prefix="\${AUTOBUILD_PACKAGES_DIR}" --libdir="\${prefix}/lib/debug" --includedir="\${prefix}/include/idn"
            make
            make install DESTDIR="$stage"

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make check
            fi

            make distclean

            CFLAGS="$opts -O2" CXXFLAGS="$opts -O2" LDFLAGS="$opts" \
                ./configure --prefix="\${AUTOBUILD_PACKAGES_DIR}" --libdir="\${prefix}/lib/release" --includedir="\${prefix}/include/idn"
            make
            make install DESTDIR="$stage"

            # conditionally run unit tests
            if [ "${DISABLE_UNIT_TESTS:-0}" = "0" ]; then
                make check
            fi

            make distclean
        ;;
    esac

    mkdir -p "$stage/LICENSES"
    cp "COPYING.LESSERv2" "$stage/LICENSES/libidn.txt"
popd
pass
