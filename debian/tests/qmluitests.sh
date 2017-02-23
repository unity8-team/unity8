#!/bin/sh
# -*- Mode: sh; indent-tabs-mode: nil; tab-width: 4 -*-

# log all commands and abort on error
set -xe

DEB_HOST_MULTIARCH=$(dpkg-architecture -qDEB_HOST_MULTIARCH)

export ARTIFACTS_DIR="${ADT_ARTIFACTS}"

export MIR_SERVER_PLATFORM_GRAPHICS_LIB="/usr/lib/${DEB_HOST_MULTIARCH}/mir/server-platform/server-mesa-x11.so.12"

/usr/lib/$DEB_HOST_MULTIARCH/unity8/tests/scripts/xvfballtests.sh
