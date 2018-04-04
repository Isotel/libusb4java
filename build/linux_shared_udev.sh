#!/bin/bash
# ============================================================================
# Build script for Linux.
#
# The script automatically compiles the binary for the local architecture and
# creates the corresponding JAR file in the target folder.
#
# Requirements: cmake, make, curl, jar
# ============================================================================

# Fail on all errors
set -e

# Software versions
LIBUSB_VERSION=1.0.21
EUDEV_VERSION=3.1.5

# Determine directories
cd "$(dirname $0)/.."
PROJECT_DIR="$(pwd)"
TARGET_DIR="$PROJECT_DIR/target"
BUILD_DIR="$TARGET_DIR/build"
DOWNLOAD_DIR="$TARGET_DIR/downloads"
ROOT_DIR="$BUILD_DIR/root"

# Standard compiler and linker flags
CFLAGS="-I$ROOT_DIR/include"
LDFLAGS="-L$ROOT_DIR/lib"

# Clean up build directory
rm -rf "$BUILD_DIR"

# Create download directory if not already present
mkdir -p "$DOWNLOAD_DIR"

# Determine OS and architecture
OS=linux
case "$(arch)" in
    "x86_64")
        ARCH=x86_64
        ;;
    "i"[3456]"86")
        ARCH=x86
        ;;
    "armv"*)
        ARCH=arm
        # Set compiler flags for Raspberry Pi 1 compatibility
        CFLAGS="$CFLAGS -marm -march=armv6zk -mcpu=arm1176jzf-s -mfloat-abi=hard -mfpu=vfp"
        ;;
    *)
        echo "Unknown platform: $(arch)"
        exit 1
esac
echo "Building for platform $OS-$ARCH"

# Export compiler and linker flags
export CFLAGS LDFLAGS

# Download and build libusb
LIBUSB_TARBALL="libusb-$LIBUSB_VERSION.tar.bz2"
LIBUSB_SOURCE="http://downloads.sf.net/project/libusb/libusb-1.0/libusb-$LIBUSB_VERSION/$LIBUSB_TARBALL"
LIBUSB_TARGET="$DOWNLOAD_DIR/$LIBUSB_TARBALL"
if [ ! -f "$LIBUSB_TARGET" ]
then
    curl -C - -o "$LIBUSB_TARGET.download" -L "$LIBUSB_SOURCE"
    mv -f "$LIBUSB_TARGET.download" "$LIBUSB_TARGET"
fi
mkdir -p "$BUILD_DIR/libusb"
cd "$BUILD_DIR/libusb"
tar xvf "$LIBUSB_TARGET" --strip-components=1
./configure --disable-shared --enable-static --with-pic --prefix=""
make install-strip DESTDIR="$ROOT_DIR"

# Build libusb4java
mkdir -p "$BUILD_DIR/libusb4java"
cd "$BUILD_DIR/libusb4java"
cmake "$PROJECT_DIR" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="" \
    -DLibUsb_INCLUDE_DIRS="$ROOT_DIR/include/libusb-1.0" \
    -DLibUsb_LIBRARIES="$ROOT_DIR/lib/libusb-1.0.a" \
    -DLibUsb_LDFLAGS="-pthread -lrt" \
    -DLINK_UDEV_SHARED=ON
make VERBOSE=1  install/strip DESTDIR="$ROOT_DIR"

# Create the JAR file
mkdir -p "$BUILD_DIR/classes/org/usb4java/$OS-$ARCH"
cp "$ROOT_DIR/lib/libusb4java.so" "$BUILD_DIR/classes/org/usb4java/$OS-$ARCH"
jar cf "$BUILD_DIR/libusb4java-$OS-$ARCH.jar" -C "$BUILD_DIR/classes" org
