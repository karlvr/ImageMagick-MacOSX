ImageMagick for Mac OS X
========================

Build scripts for creating a package for ImageMagick on Mac OS X.

Download and install Packages, which is the application that builds the installer packages:  
http://s.sudre.free.fr/Software/Packages/about.html

You must have Home Brew installed, as it is used to install dependencies on your system:  
http://mxcl.github.io/homebrew/

You must have Ghostscript installed. This is in order to build ImageMagick with ps support. I suggest
installing Ghostscript using the installer bundle I've created, available from:  
https://github.com/karlvr/Ghostscript-MacOSX

You should have a Developer ID Installer identity from Apple in your Keychain. This is used to sign the package.
If you don't have this identity the script will skip the signing stage.

Download the latest ImageMagick source:  
http://www.imagemagick.org/download/ImageMagick.tar.gz

Extract the ImageMagick source into this repository, to create a folder such as ``ImageMagick-6.8.6-3``.

Open Terminal.app to that ImageMagick source directory, then run the build script:  
``../build-packages.sh``

The build script will download dependencies, configure and compile then and the compile ImageMagick.
It also checks that all of the expected capabilities have been included successfully, and that the package
does not have any depdendencies that won't work on other systems.

If you have XQuartz installed, the build script will create an XQuartz build of ImageMagick as well.

The output files will be in the ``build`` directory.
