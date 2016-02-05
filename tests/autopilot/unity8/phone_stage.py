
import logging

from autopilot import logging as autopilot_logging
from autopilot.exceptions import StateNotFoundError
from ubuntuuitoolkit import UbuntuUIToolkitCustomProxyObjectBase

class PhoneStage(UbuntuUIToolkitCustomProxyObjectBase):

    def _swipe_from_right(self):
        width = self.width
        height = self.height
        start_x = width
        start_y = int(height // 2)
        end_x = 0
        end_y = start_y
        self.pointing_device.drag(start_x, start_y, end_x, end_y)

    def swipe_to_top(self):
        flickable = self.select_single(
                'QQuickFlickable', objectName='spreadView')
        while not flickable.atXEnd:
            self._swipe_from_right()
            flickable.moving.wait_for(False)
