# QtCreator/Qt build scripts

These scripts provides quick ways to build and package Qt and QtCreator.
They currently target Debian stable but can easily be modified to fit other systems.

A Docker container can optionally be used to perform the build.

CCache can also optionally be used.

```sh
$ ./build-qt.sh -h
Usage:
./build-qt.sh --src <source directory> --build <build directory> --prefix <install directory>
              --package-name <string> --package-version <version>
              [--docker-image <docker image>]
              [--ccache <ccache directory>] [-v]
```

```sh
$ ./build-qtcreator.sh -h
Usage:
./build-qtcreator.sh --src <source directory> --build <build directory> --prefix <install directory>
                     --package-name <string> --package-version <version>
                     [--qmake <qmake executable>]
                     [--docker-image <docker image>] [--docker-install-qt <deb package>]
                     [--ccache <ccache directory>] [-v]
```

```sh
# Optional, remove the --docker-* options if you don't use the container.
docker build -t qt-buil-env docker/

# Optional, remove the --ccache option if you don't use ccache.
mkdir cache

mkdir qt-5.15.2-src qt-5.15.2-bld && \
  wget https://download.qt.io/official_releases/qt/5.15/5.15.2/single/qt-everywhere-src-5.15.2.tar.xz -O - | \
  tar -xJ --strip-components=1 -C qt-5.15.2-src

./build-qt.sh --src /qt-5.15.2-src --build qt-5.15.2-bld --prefix /opt/qt-5.15.2 \
  --package-name my-qt5 --package-version 5.15.2-0 \
  --docker-image qt-build-env --ccache cache

# You should get a my-qt5_5.15.2-0_amd64.deb file.

mkdir qtcreator-4.13.3-src qtcreator-4.13.3-bld && \
  wget https://download.qt.io/official_releases/qtcreator/4.13/4.13.3/qt-creator-opensource-src-4.13.3.tar.xz -O - | \
  tar -xJ --strip-components=1 -C qtcreator-4.13.3-src

./build-qtcreator.sh --src qtcreator-4.13.3-src --build qtcreator-4.13.3-bld --prefix /opt/qtcreator-4.13.3 \
  --package-name my-qtcreator --package-version 4.13.3-0 \
  --docker-image qt-build-env --docker-install-qt my-qt5_5.15.2-0_amd64.deb --ccache cache

# You should get a my-qtcreator_4.13.3-0_amd64.deb file.
```

# License

These scripts are released under the terms of the MIT License. See the LICENSE.txt file for more details.
