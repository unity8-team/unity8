
import logging

from autopilot import logging as autopilot_logging
from autopilot.exceptions import StateNotFoundError
from ubuntuuitoolkit import UbuntuUIToolkitCustomProxyObjectBase

from unity8 import shell as shell_helper

class PhoneStage(UbuntuUIToolkitCustomProxyObjectBase):

    def _get_app_windows(self):
        """
        :return: A list of displayed ApplicationWindow objects.
        """
        return self.select_many('ApplicationWindow')

    def _swipe_from_right(self):
        width = self.width
        height = self.height
        start_x = width
        start_y = int(height // 2)
        end_x = 0
        end_y = start_y
        self.pointing_device.drag(start_x, start_y, end_x, end_y)

    def get_all_app_windows(self, include_off_screen=True):
        """
        :param include_off_screen: Whether or not to include off screen apps

        :return: Ordered list of all app window objects in task switcher.
        """
        return shell_helper.order_by_x_coord(
                self._get_app_windows(), include_off_screen=include_off_screen)

    def get_app_window_names(self, include_off_screen=True):
        """
        :parem include_off_screen: Whether or not to include off screen apps

        :return: ordered list of app window object names for each app
            displayed
        """
        return [app.objectName for app in self.get_all_app_windows(
            include_off_screen)]

    def swipe_to_top(self):
        flickable = self.select_single(
                'QQuickFlickable', objectName='spreadView')
        while not flickable.atXEnd:
            self._swipe_from_right()
            flickable.moving.wait_for(False)
