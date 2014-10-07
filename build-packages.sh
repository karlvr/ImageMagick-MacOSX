#!/bin/bash

if [ ! -d "magick" ]; then
	echo "Must run this script from inside the ImageMagick distribution being built"
	exit 1
fi

if [ ! -d "/opt/Ghostscript" ]; then
	echo "Ghostscript not installed. Please install Ghostscript first in order to build ImageMagick with ps support."
	echo "You could use the installer I've prepared for Ghostscript from "
	exit 1
fi

checkSuccess() {
	if [ $? != 0 ]; then
		echo "*** Failed: $MESSAGE"
		exit 1
	fi
}

WD=${PWD##*/}
REV=${WD/ImageMagick-/}
VERSION=${REV%-*}

PACKAGE_CONFIG="../ImageMagick.pkgproj"
/usr/local/bin/packagesutil --file "${PACKAGE_CONFIG}" set package-1 version "$VERSION"

export PKG_CONFIG_PATH=

########################
# Dependencies

if [ ! -h "jpeg" ]; then
	# Check latest source: brew edit libjpeg
	brew install libjpeg && \
	curl -O http://www.ijg.org/files/jpegsrc.v8d.tar.gz && \
	tar zxf jpegsrc.v8d.tar.gz && \
	ln -s jpeg-8d jpeg && \
	pushd jpeg && \
	./configure --disable-shared && \
	make && \
	popd
	MESSAGE="compile jpeg" ; checkSuccess
fi

if [ ! -h "jp2" ]; then
	# Check latest source: brew edit jasper
	brew install jasper && \
	curl -O http://download.osgeo.org/gdal/jasper-1.900.1.uuid.tar.gz && \
	tar zxf jasper-1.900.1.uuid.tar.gz && \
	ln -s jasper-1.900.1.uuid jp2 && \
	pushd jp2 && \
	./configure --disable-shared && \
	make && \
	popd
	MESSAGE="compile jp2" ; checkSuccess
fi

if [ ! -h "tiff" ]; then
	# Check latest source: brew edit libtiff
	# Disable lzma as ImageMagick doesn't include lzma in the list of libs required to link with libtiff
	brew install libtiff && \
	curl -O http://download.osgeo.org/libtiff/tiff-4.0.3.tar.gz && \
	tar zxf tiff-4.0.3.tar.gz && \
	ln -s tiff-4.0.3 tiff && \
	pushd tiff && \
	./configure --disable-shared --disable-lzma && \
	make && \
	popd
	MESSAGE="compile tiff" ; checkSuccess
fi

if [ ! -h "lcms" ]; then
	# Check latest source: brew edit lcms
	brew install lcms && \
	curl -OL http://sourceforge.net/projects/lcms/files/lcms/1.19/lcms-1.19.tar.gz && \
	tar zxf lcms-1.19.tar.gz && \
	ln -s lcms-1.19 lcms && \
	pushd lcms && \
	./configure --disable-shared && \
	make && \
	popd
	MESSAGE="compile lcms" ; checkSuccess
fi

if [ ! -h "png" ]; then
	# Check latest source: brew edit libpng
	brew install libpng && \
	curl -OL http://downloads.sf.net/project/libpng/libpng15/older-releases/1.5.14/libpng-1.5.14.tar.gz && \
	tar zxf libpng-1.5.14.tar.gz && \
	ln -s libpng-1.5.14 png && \
	pushd png && \
	./configure --disable-shared && \
	make && \
	popd
	MESSAGE="compile png" ; checkSuccess
fi

if [ ! -h "fftw" ]; then
	# Check latest source: brew edit fftw
	brew install fftw && \
	curl -OL http://www.fftw.org/fftw-3.3.3.tar.gz && \
	tar zxf fftw-3.3.3.tar.gz && \
	ln -s fftw-3.3.3 fftw && \
	pushd fftw && \
	./configure --disable-shared CXXFLAGS=-fPIC CFLAGS=-fPIC && \
	make && \
	ln -s api/fftw3.h . && \
	popd
	MESSAGE="compile fftw" ; checkSuccess
fi

if [ ! -h "lzma" ]; then
	# Check latest source: brew edit xz
	brew install xz && \
	curl -OL http://fossies.org/linux/misc/xz-5.0.5.tar.gz && \
	tar jxf xz-5.0.5.tar.gz && \
	ln -s xz-5.0.5/src/liblzma/ lzma && \
	pushd xz-5.0.5 && \
	./configure --disable-shared && \
	make && \
	popd
	MESSAGE="compile lzma" ; checkSuccess
fi

if [ ! -h "webp" ]; then
	# Check latest source: brew edit webp
	brew install webp && \
	curl -OL http://webp.googlecode.com/files/libwebp-0.3.1.tar.gz && \
	tar zxf libwebp-0.3.1.tar.gz && \
	ln -s libwebp-0.3.1 webp && \
	pushd webp && \
	./configure --disable-shared && \
	make && \
	ln -s src/.libs . && \
	ln -s src/webp . && \
	popd
	MESSAGE="compile webp" ; checkSuccess
fi

# Check delegates
checkDelegate() {
	/opt/ImageMagick/bin/convert -version | grep Delegates | grep $DELEGATE > /dev/null
	if [ $? != 0 ]; then
		echo "*** FAIL Missing delegate: $DELEGATE"
		exit 1
	fi
}

checkDelegates() {
	DELEGATE=bzlib ; checkDelegate
	DELEGATE=fftw ; checkDelegate
	DELEGATE=jng ; checkDelegate
#	DELEGATE=jp2 ; checkDelegate
	DELEGATE=jpeg ; checkDelegate
	DELEGATE=lcms ; checkDelegate
	DELEGATE=lzma ; checkDelegate
	DELEGATE=png ; checkDelegate
# We don't seem to be able to detect ps delegate anymore
#	DELEGATE=ps ; checkDelegate
	DELEGATE=tiff ; checkDelegate
	DELEGATE=xml ; checkDelegate
	DELEGATE=zlib ; checkDelegate
}

checkFormat() {
	/opt/ImageMagick/bin/convert -list format | grep -i $FORMAT > /dev/null
	if [ $? != 0 ]; then
		echo "*** FAIL Missing format: $FORMAT"
		exit 1
	fi
}

checkFormats() {
#	FORMAT=jp2; checkFormat
	FORMAT=jpg; checkFormat
	FORMAT=png; checkFormat
	FORMAT=tiff; checkFormat
	FORMAT=webp; checkFormat
}

########################
# No XQuartz

./configure --prefix /opt/ImageMagick --enable-delegate-build --without-x --without-freetype --disable-static CFLAGS=-mmacosx-version-min=10.5 && \
sudo rm -rf /opt/ImageMagick && \
make clean && \
make && \
sudo make install

MESSAGE="compile ImageMagick" ; checkSuccess

echo "*** CHECKING no XQuartz build for expected delegates and formats"
checkDelegates
checkFormats

otool -L /opt/ImageMagick/bin/convert | grep "/usr/local" > /dev/null
if [ $? == 0 ]; then
	echo "*** FAIL /opt/ImageMagick/bin/convert links to /usr/local"
	exit 1
fi
otool -L /opt/ImageMagick/bin/convert | grep "X11" > /dev/null
if [ $? == 0 ]; then
	echo "*** FAIL /opt/ImageMagick/bin/convert links X11"
	exit 1
fi

/usr/local/bin/packagesbuild "${PACKAGE_CONFIG}"
/usr/bin/productsign --sign "Developer ID Installer" "../build/ImageMagick.pkg" "../build/ImageMagick-$REV.pkg"
if [ $? != 0 ]; then
	mv "../build/ImageMagick.pkg" "../build/ImageMagick-$REV.pkg"
fi
/bin/rm "../build/ImageMagick.pkg"
pushd ../build
/usr/bin/zip "ImageMagick-$REV.pkg.zip" "ImageMagick-$REV.pkg"
popd



########################
# XQuartz version

if [ -d "/opt/X11" ]; then
export PKG_CONFIG_PATH=/opt/X11/lib/pkgconfig

./configure --prefix /opt/ImageMagick --enable-delegate-build --with-x --x-libraries /usr/X11/lib --disable-static CFLAGS=-mmacosx-version-min=10.5 && \
sudo rm -rf /opt/ImageMagick && \
make clean && \
make && \
sudo make install

MESSAGE="compile ImageMagick with XQuartz" ; checkSuccess

echo "*** CHECKING XQuartz build for expected delegates and formats"
checkDelegates

DELEGATE=x ; checkDelegate
DELEGATE=freetype ; checkDelegate
DELEGATE=fontconfig ; checkDelegate

checkFormats

otool -L /opt/ImageMagick/bin/convert | grep "/usr/local" > /dev/null
if [ $? == 0 ]; then
	echo "*** FAIL convert links to /usr/local"
	exit 1
fi
otool -L /opt/ImageMagick/bin/convert | grep "X11" > /dev/null
if [ $? != 0 ]; then
	echo "*** FAIL convert doesn't link X11"
	exit 1
fi

/usr/local/bin/packagesbuild "${PACKAGE_CONFIG}"
/usr/bin/productsign --sign "Developer ID Installer" "../build/ImageMagick.pkg" "../build/ImageMagick-$REV-with-X.pkg"
if [ $? != 0 ]; then
	mv "../build/ImageMagick.pkg" "../build/ImageMagick-$REV-with-X.pkg"
fi
/bin/rm "../build/ImageMagick.pkg"
pushd ../build
/usr/bin/zip "ImageMagick-$REV-with-X.pkg.zip" "ImageMagick-$REV-with-X.pkg"
popd

fi # XQuartz
