#!/bin/bash
set -o errexit -o pipefail -o nounset

function filter {
    grep "$@" || test $? = 1
}

function fail() {
    >&2 echo "$@"
    exit -1
}

function join_csv {
    awk -v d=", " '{s=(NR==1?s:s d)$0}END{print s}' "$@"
}

function docker_image_exists {
    docker image inspect "$1" > /dev/null 2>&1
}

function usage {
    echo "Usage: $0 --src <source directory> --build <build directory> --prefix <install directory> --package-name <string> --package-version <version> [--qmake <qmake executable>] [--docker-image <docker image>] [--docker-install-qt <deb package>] [--ccache <ccache directory>] [-v]"
}

QMAKE=
VERBOSE=

while [[ $# -gt 0 ]]; do
    case $1 in
    --src)
        export SRCDIR="$2"
        shift 2
        ;;
    --build)
        export BUILDDIR="$2"
        shift 2
        ;;
    --prefix)
        export PREFIX="$2"
        shift 2
        ;;
    --qmake)
        export QMAKE="$2"
        shift 2
        ;;
    --package-name)
        export PKGNAME="$2"
        shift 2
        ;;
    --package-version)
        export PKGVERSION="$2"
        shift 2
        ;;
    --docker-image)
        DOCKER_IMAGE="$2"
        shift 2
        ;;
    --docker-install-qt)
        export QTDEB="$2"
        shift 2
        ;;
    --ccache)
        export CCACHE_DIR="$2"
        unset CCACHE_DISABLE
        shift 2
        ;;
    -v | --verbose)
        VERBOSE=y
        shift
        ;;
    -h | --help)
        usage
        exit
        ;;
    *)
        fail "$0: Unknown option $1"
        ;;
    esac
done

[[ -v SRCDIR ]] || fail "$0: Source directory not specified"
[ -d "$SRCDIR" ] || fail "$0: Source directory does not exists"

[[ -v BUILDDIR ]] || fail "$0: Build directory not specified"
[ -d "$BUILDDIR" ] || fail "$0: Build directory does not exists"
[ -w "$BUILDDIR" ] || fail "$0: Build directory is not writable"

[[ $PKGNAME =~ ^[A-Za-z0-9.-]+$ ]] || fail "$0: Invalid package name"

[[ $PKGVERSION =~ ^[0-9]\.[A-Za-z0-9.+-:]*$ ]] || fail "$0: Invalid package version"

export PREFIX="${PREFIX:-/opt/${PKGNAME}${PKGVERSION%%.*}}"

export EXTPREFIX=$PWD/${PKGNAME}_${PKGVERSION}_$(dpkg --print-architecture)

function start_container {
    local ccache_args=()
    if [[ -v CCACHE_DIR && ( ! -v CCACHE_DISABLE ) ]]; then
        ccache_args+=(-v "$(realpath -s "$CCACHE_DIR"):/cache" -e CCACHE_DIR=/cache)
    fi

    docker run -d --rm -v "$PWD:/work" -v "$(realpath -s "$SRCDIR"):/src" -v "$(realpath -s "$BUILDDIR"):/build" "${ccache_args[@]}" -it "$DOCKER_IMAGE" bash
}

function build_with_docker {
    local CONTAINER=$(start_container)
    trap "docker stop $CONTAINER" EXIT

    [[ -v QTDEB ]] && docker exec $CONTAINER dpkg -i "$QTDEB"

    [[ -v QTDEB && -z "$QMAKE" ]] && QMAKE=$(dpkg -c "$QTDEB" | rev | awk '{print $1}' | rev | grep 'qmake$' | sed -e 's/^.//g') || QMAKE=qmake

    docker exec --user $(id -u):$(id -g) $CONTAINER bash -x ./build-qtcreator.sh --src /src --build /build --prefix "$PREFIX" --qmake "$QMAKE" --package-name "$PKGNAME" --package-version "$PKGVERSION"
}

function build {
    mkdir -p "$BUILDDIR"
    (
        cd "$BUILDDIR"

        export LLVM_INSTALL_DIR=/usr/lib/llvm-11
        "$QMAKE" /src/qtcreator.pro
        make -j$(nproc) qmake_all
        make -j$(nproc)
        env INSTALL_ROOT="$EXTPREFIX/$PREFIX" make -j$(nproc) install
    )
}

function prepare_package {
    # # List libraries provided by QtCreator
    find "$EXTPREFIX/$PREFIX" -type f,l | filter -P '\.so(\.[0-9]+)*$' | rev | cut -d/ -f1 | rev | sort -u >/tmp/libraries.txt
    if [ "$VERBOSE" = y ]; then
        >&2 echo "LIBRARIES: $(join_csv /tmp/libraries.txt)"
    fi

    # List dependencies
    {
        ldd $EXTPREFIX/$PREFIX/lib/qtcreator/*.so
        ldd $(file $EXTPREFIX/$PREFIX/bin/* $EXTPREFIX/$PREFIX/libexec/qtcreator/* | filter -F ELF | cut -d: -f1)
    } | filter -v -F linux-vdso.so | filter "^\s" | awk '{print $1}' | rev | cut -d/ -f1 | rev | cut -d: -f1 | sort -u >/tmp/dependencies.txt
    if [ "$VERBOSE" = y ]; then
        >&2 echo "DEPENDENCIES: $(join_csv /tmp/dependencies.txt)"
    fi

    comm -23 /tmp/dependencies.txt /tmp/libraries.txt >/tmp/external-dependencies.txt
    if [ "$VERBOSE" = y ]; then
        >&2 echo "EXTERNAL LIBRARIES: $(join_csv /tmp/external-dependencies.txt)"
    fi

    # while read NAME; do
    #    echo "##### $NAME"
    #    dpkg -S "*$NAME"
    # done < /tmp/external-dependencies.txt

    dpkg -S $(sed 's/^/*/g' /tmp/external-dependencies.txt) | filter -v -F -e i386 -e lib32 | cut -d: -f1 | filter -v -- '-dev$' | sort -u >/tmp/depends.txt
    if [ "$VERBOSE" = y ]; then
        >&2 echo "DEPENDS: $(join_csv /tmp/depends.txt)"
    fi

    mkdir -p $EXTPREFIX/DEBIAN
    cat <<EOF >$EXTPREFIX/DEBIAN/control
Package: ${PKGNAME}
Version: ${PKGVERSION}
Architecture: $(dpkg --print-architecture)
Maintainer: Cyrille Faucheux <cyrille.faucheux@gmail.com>
Description: integrated development environment (IDE) for Qt
 Qt Creator is a cross-platform integrated development environment (IDE) designed to make development with the Qt application framework faster and easier.
 It includes:
 * An advanced C++ code editor
 * Integrated GUI layout and forms designer
 * Project and build management tools
 * Integrated, context-sensitive help system
 * Visual debugger
 * Rapid code navigation tools
 * Supports multiple platforms
 * Qt Quick Designer
  Site: https://doc.qt.io/qt-5/topics-app-development.html
Depends: $(join_csv /tmp/depends.txt)
EOF

    >&2 echo "DEBIAN/control"
    >&2 cat $EXTPREFIX/DEBIAN/control
}

function make_package {
    dpkg-deb --build --root-owner-group "$EXTPREFIX"
}

if [[ -v DOCKER_IMAGE ]]; then
    docker_image_exists "$DOCKER_IMAGE" || fail "$0: unknown docker image"
    build_with_docker
else
    build
    prepare_package
    make_package
fi
