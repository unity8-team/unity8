# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Autopilot Test Suite
# Copyright (C) 2012-2013 Canonical
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

"""unity shell autopilot tests and emulators - sub level package."""

from autopilot.input import Pointer, Touch

from contextlib import contextmanager
from time import sleep
from functools import wraps
import logging


logger = logging.getLogger(__name__)


def with_lightdm_mock(mock_type):
    """A simple decorator that sets up the LightDM mock for a single test."""
    def with_lightdm_mock_internal(fn):
        @wraps(fn)
        def wrapper(*args, **kwargs):
            tests_self = args[0]
            tests_self.patch_lightdm_mock(mock_type)
            return fn(*args, **kwargs)
        return wrapper
    return with_lightdm_mock_internal


def disable_qml_mocking(fn):
    """Simple decorator that disables the QML mocks from being loaded."""
    @wraps(fn)
    def wrapper(*args, **kwargs):
        tests_self = args[0]
        tests_self._qml_mock_enabled = False
        return fn(*args, **kwargs)
    return wrapper


@contextmanager
def finger_down(start_x, start_y, device=None):
    """Allow actions and asserts to be made while the finger is still down
    while dragging is in operation.

    Returns a pointer object that overrides drag so that it doesn't release
    once it's done dragging.

    This context-manager ensures that touch cleanup happens (namely releasing
    the finger).

    """
    class PointerOverride(Pointer):
        def __init__(self, device):
            super(PointerOverride, self).__init__(device)

        def drag(self, x2, y2):
            x1 = self.x
            y1 = self.y
            cur_x = x1
            cur_y = y1
            dx = 1.0 * (x2 - x1) / 100
            dy = 1.0 * (y2 - y1) / 100
            for i in range(0, 100):
                self._device._finger_move(int(cur_x), int(cur_y))
                sleep(0.002)
                cur_x += dx
                cur_y += dy
            self._device._finger_move(int(x2), int(y2))

    if device is None:
        device = Touch.create()
    pointer = PointerOverride(device)

    try:
        pointer.move(start_x, start_y)
        pointer.press()
        yield pointer
    finally:
        try:
            pointer.release()
        except RuntimeError:
            logger.info(
                "While using finger down pointer.release was called without"
                "pressed being called first."
            )


class DragMixin(object):
    def _drag(self, x1, y1, x2, y2):
        cur_x = x1
        cur_y = y1
        dx = 1.0 * (x2 - x1) / 100
        dy = 1.0 * (y2 - y1) / 100
        for i in range(0, 100):
            self.touch._finger_move(int(cur_x), int(cur_y))
            sleep(0.002)
            cur_x += dx
            cur_y += dy
        self.touch._finger_move(int(x2), int(y2))
