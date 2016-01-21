#!/bin/sh

if [ -z "$1" ] || ! [ -d "$1" ]
  then
    echo "First argument should be a directory containing the fat libs."
    exit 1
fi

if [ -z "$2" ] || ! [ -d "$2" ]
  then
    echo "Second argument should be a directory where extracted thin libs and merged fat lib will be written."
    exit 1
fi

FAT_LIBS_DIR="$1"
OUTPUT_DIR="$2"

ARCHS=""
IFS_TMP="$IFS"
for lib in `ls $FAT_LIBS_DIR`; do
    IFS=':'

    LIB_PATH="$FAT_LIBS_DIR/$lib"

    echo "Processing $lib"
    for arch in `lipo -info "$LIB_PATH"`; do
        ARCHS="$arch"
    done
    echo "Available architectures: $ARCHS"
    IFS=' '
    for arch in `echo $ARCHS`; do
	OUTPUT_FILE="$OUTPUT_DIR/$lib""_$arch"
	echo "Extracting $arch from $lib into $OUTPUT_FILE"
	
	lipo "$FAT_LIBS_DIR/$lib" -thin "$arch" -output "$OUTPUT_FILE"
    done
done

IFS="$IFS_TMP"
LIBS_COMBINED=""

for arch in `echo $ARCHS`; do
    arch_libs=""
    for thin_lib in `ls $OUTPUT_DIR | egrep $arch$`; do
	arch_libs="$arch_libs $OUTPUT_DIR/$thin_lib"

    done
    LIB_COMBINED="$OUTPUT_DIR/libCombined_$arch.a"
    LIBS_COMBINED="$LIBS_COMBINED -arch $arch $LIB_COMBINED"
    
    libtool -static $arch_libs -o "$LIB_COMBINED"
    
done

lipo -create $LIBS_COMBINED -output "$OUTPUT_DIR/libCombined.a"





