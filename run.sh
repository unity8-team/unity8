#!/bin/sh

. /etc/environment
export QML2_IMPORT_PATH

UNITY8_PATH=./builddir/src/unity8
UNITY8_DASH_PATH=./builddir/Dash/src/unity8-dash
GDB=false
FAKE=false
PINLOCK=false
KEYLOCK=false
USE_MOCKS=false
MOUSE_TOUCH=true

usage() {
    echo "usage: "$0" [OPTIONS]\n" >&2
    echo "Script to run the shell.\n" >&2
    echo "OPTIONS:" >&2
    echo " -f, --fake Force use of fake Qml modules." >&2
    echo " -p, --pinlock Use a pin protected user." >&2
    echo " -k, --keylock Use a passphrase protected user." >&2
    echo " -g, --gdb Run through gdb." >&2
    echo " -h, --help Show this help." >&2
    echo " -m, --nomousetouch Run without -mousetouch argument." >&2
    echo >&2
    exit 1
}

ARGS=`getopt -n$0 -u -a --longoptions="fake,pinlock,keylock,gdb,help,nomousetouch" -o "fpkghm" -- "$@"`
[ $? -ne 0 ] && usage
eval set -- "$ARGS"

while [ $# -gt 0 ]
do
    case "$1" in
       -f|--fake)  FAKE=true; USE_MOCKS=true;;
       -p|--pinlock)  PINLOCK=true; USE_MOCKS=true;;
       -k|--keylock)  KEYLOCK=true; USE_MOCKS=true;;
       -g|--gdb)   GDB=true;;
       -h|--help)  usage;;
       -m|--nomousetouch)  MOUSE_TOUCH=false;;
       --)         shift;break;;
    esac
    shift
done

if $FAKE; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/builddir/tests/mocks/libusermetrics:$PWD/builddir/tests/mocks/LightDM/single
fi

if $PINLOCK; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/builddir/tests/mocks/libusermetrics:$PWD/builddir/tests/mocks/LightDM/single-pin
fi

if $KEYLOCK; then
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/builddir/tests/mocks/libusermetrics:$PWD/builddir/tests/mocks/LightDM/single-passphrase
fi

if $USE_MOCKS; then
  rm -f $PWD/builddir/nonmirplugins/LightDM # undo symlink (from below) for cleanliness
  export QML2_IMPORT_PATH=$QML2_IMPORT_PATH:$PWD/builddir/tests/mocks:$PWD/builddir/plugins:$PWD/builddir/modules
else
  # Still fake no-login user for convenience (it's annoying to be prompted for your password when testing)
  # And in particular, just link our LightDM mock into the nonmirplugins folder.  We don't want the rest of
  # our plugins to be used.
  ln -s $PWD/builddir/tests/mocks/LightDM $PWD/builddir/nonmirplugins/
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PWD/builddir/tests/mocks/LightDM/single
fi

UNITY8_ARGS=""
if $MOUSE_TOUCH; then
  UNITY8_ARGS="$UNITY8_ARGS -mousetouch"
fi

control_c()
{
  /sbin/initctl stop unity8
  exit $?
}

if $GDB; then
  gdb -ex run --args $UNITY8_PATH $UNITY8_ARGS $@
else
  if ! status=`/sbin/initctl status unity8`; then
    echo "Unity8 upstart job unavailable, please install unity8"
    echo "or copy data/unity8.conf to ~/.config/upstart"
    exit 1
  fi
  if [ "$status" != "unity8 stop/waiting" ]; then
    echo "Unity8 is already running, please stop it first"
    exit 2
  fi

  if ! status=`/sbin/initctl status unity8-dash` ; then
    echo "Unity8 dash upstart job unavailable, please install unity8"
    echo "or copy data/unity8-dash.conf to ~/.config/upstart"
    exit 3
  fi
  if [ "$status" != "unity8-dash stop/waiting" ]; then
    echo "Unity8 Dash is already running, please stop it first"
    exit 4
  fi

  trap control_c INT

  /sbin/initctl start unity8 BINARY="`readlink -f $UNITY8_PATH` $UNITY8_ARGS $@" QML2_IMPORT_PATH=$QML2_IMPORT_PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH
  /sbin/initctl restart unity8-dash BINARY="`readlink -f $UNITY8_DASH_PATH` $UNITY8_ARGS $@" QML2_IMPORT_PATH=$QML2_IMPORT_PATH LD_LIBRARY_PATH=$LD_LIBRARY_PATH
  tailf -n 0 ~/.cache/upstart/unity8.log
fi
