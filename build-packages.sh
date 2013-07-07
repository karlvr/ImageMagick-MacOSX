#!/bin/bash

if [ ! -d "magick" ]; then
	echo "Must run this script from inside the ImageMagick distribution being built"
	exit 1
fi

WD=${PWD##*/}
REV=${WD/ImageMagick-/}
VERSION=${REV%-*}

PACKAGE_CONFIG="../ImageMagick.pkgproj"
/usr/local/bin/packagesutil --file "${PACKAGE_CONFIG}" set package-1 version "$VERSION"

export PKG_CONFIG_PATH=

# Dependencies
if [ ! -h "jpeg" ]; then
	brew install libjpeg && \
	curl -O http://www.ijg.org/files/jpegsrc.v8d.tar.gz && \
	tar zxf jpegsrc.v8d.tar.gz && \
	ln -s jpeg-8d jpeg && \
	pushd jpeg && \
	./configure --disable-shared && \
	make && \
	popd
fi

if [ ! -h "jp2" ]; then
	brew install jasper && \
	curl -O http://download.osgeo.org/gdal/jasper-1.900.1.uuid.tar.gz && \
	tar zxf jasper-1.900.1.uuid.tar.gz && \
	ln -s jasper-1.900.1.uuid jp2 && \
	pushd jp2 && \
	./configure --disable-shared && \
	make && \
	popd
fi

if [ ! -h "tiff" ]; then
	brew install libtiff && \
	curl -O http://download.osgeo.org/libtiff/tiff-4.0.3.tar.gz && \
	tar zxf tiff-4.0.3.tar.gz && \
	ln -s tiff-4.0.3 tiff && \
	pushd tiff && \
	./configure --disable-shared && \
	make && \
	popd
fi

if [ ! -h "lcms" ]; then
	brew install lcms && \
	curl -OL http://sourceforge.net/projects/lcms/files/lcms/1.19/lcms-1.19.tar.gz && \
	tar zxf lcms-1.19.tar.gz && \
	ln -s lcms-1.19 lcms && \
	pushd lcms && \
	./configure --disable-shared && \
	make && \
	popd
	
fi

if [ ! -h "png" ]; then
	brew install libpng && \
	curl -OL http://downloads.sf.net/project/libpng/libpng15/older-releases/1.5.14/libpng-1.5.14.tar.gz && \
	tar zxf libpng-1.5.14.tar.gz && \
	ln -s libpng-1.5.14 png && \
	pushd png && \
	./configure --disable-shared && \
	make && \
	popd
fi

if [ ! -h "fftw" ]; then
	brew install fftw && \
	curl -OL http://www.fftw.org/fftw-3.3.3.tar.gz && \
	tar zxf fftw-3.3.3.tar.gz && \
	ln -s fftw-3.3.3 fftw && \
	pushd fftw && \
	./configure --disable-shared CXXFLAGS=-fPIC CFLAGS=-fPIC && \
	make && \
	popd
fi

if [ ! -h "lzma" ]; then
	brew install xz && \
	curl -OL http://tukaani.org/xz/xz-5.0.4.tar.bz2 && \
	tar jxf xz-5.0.4.tar.bz2 && \
	ln -s xz-5.0.4/src/liblzma/ lzma && \
	pushd xz-5.0.4 && \
	./configure --disable-shared && \
	make && \
	popd
fi

if [ ! -h "webp" ]; then
	brew install webp && \
	curl -OL http://webp.googlecode.com/files/libwebp-0.3.0.tar.gz && \
	tar zxf libwebp-0.3.0.tar.gz && \
	ln -s libwebp-0.3.0 webp && \
	pushd webp && \
	./configure --disable-shared && \
	make && \
	mkdir .libs && \
	cp src/.libs/* .libs && \
	popd
fi

./configure --prefix /opt/ImageMagick --enable-delegate-build --without-x --without-freetype --disable-static CFLAGS=-mmacosx-version-min=10.5 && \
sudo rm -rf /opt/ImageMagick && \
make && \
sudo make install

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
	DELEGATE=jp2 ; checkDelegate
	DELEGATE=jpeg ; checkDelegate
	DELEGATE=lcms ; checkDelegate
	DELEGATE=lzma ; checkDelegate
	DELEGATE=png ; checkDelegate
	DELEGATE=ps ; checkDelegate
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
	FORMAT=jp2; checkFormat
	FORMAT=jpg; checkFormat
	FORMAT=png; checkFormat
	FORMAT=tiff; checkFormat
	FORMAT=webp; checkFormat
}

checkDelegates
checkFormats

otool -L /opt/ImageMagick/bin/convert | grep "/usr/local" > /dev/null
if [ $? == 0 ]; then
	echo "*** FAIL convert links to /usr/local"
	exit 1
fi
otool -L /opt/ImageMagick/bin/convert | grep "X11" > /dev/null
if [ $? == 0 ]; then
	echo "*** FAIL convert links X11"
	exit 1
fi

/usr/local/bin/packagesbuild "${PACKAGE_CONFIG}"
/usr/bin/productsign --sign "Developer ID Installer" "../build/ImageMagick.pkg" "../build/ImageMagick-$REV.pkg"
if [ $? != 0 ]; then
	mv "../build/ImageMagick.pkg" "../build/ImageMagick-$REV.pkg"
fi
/bin/rm "../build/ImageMagick.pkg"
/usr/bin/zip "../build/ImageMagick-$REV.pkg.zip" "../build/ImageMagick-$REV.pkg"


########################
# XQuartz version

if [ -d "/opt/X11" ]; then
export PKG_CONFIG_PATH=/usr/X11/lib/pkgconfig

./configure --prefix /opt/ImageMagick --enable-delegate-build --with-x --x-libraries /usr/X11/lib --disable-static CFLAGS=-mmacosx-version-min=10.5 && \
sudo rm -rf /opt/ImageMagick && \
make clean && \
make && \
sudo make install

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
/usr/bin/zip "../build/ImageMagick-$REV-with-X.pkg.zip" "../build/ImageMagick-$REV-with-X.pkg"

fi # XQuartz
