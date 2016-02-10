
import logging

from autopilot import logging as autopilot_logging
from autopilot.exceptions import StateNotFoundError
from ubuntuuitoolkit import UbuntuUIToolkitCustomProxyObjectBase

from unity8 import shell as shell_helper

class PhoneStage(UbuntuUIToolkitCustomProxyObjectBase):

    def _get_app_window(self, app_name):
        """
        :param app_name: AppID of the app window to get
        :returns: A proxy to the application window of the specified id
        """
        window_name = 'appWindow_' + app_name
        return self.select_single('ApplicationWindow', objectName=window_name)


    def _get_app_window_touch_point(self, app_window):
        x, y, w, h = app_window.globalRect
        mid_y = y + h // 2
        next_app = self._get_next_app_window(app_window)
        if next_app:
            next_x = next_app.globalRect.x
        else:
            next_x = self.globalRect.x + self.globalRect.width
        mid_x = x + ((next_x) // 4)
        return mid_x, mid_y

    def _get_app_windows(self):
        """
        :return: A list of displayed ApplicationWindow objects.
        """
        return self.select_many('ApplicationWindow')

    def _get_app_window_object_names(self, app_windows):
        return [app_window.objectName for app_window in app_windows]

    def _get_app_window_position(self, app_windows, app_window):
        return self._get_app_window_object_names(app_windows).index(
            app_window.objectName)

    def _get_next_app_window(self, app_window):
        apps = self.get_all_app_windows(include_off_screen=False)
        next_app = self._get_app_window_position(apps, app_window) + 1
        try:
            return apps[next_app]
        except IndexError:
            return None

    def _press_app(self, app_window):
        import pdb
        pdb.set_trace()
        x, y = self._get_app_window_touch_point(app_window)
        self.pointing_device.move(x, y)
        self.pointing_device.click()

    def _swipe_from_app_to_right_edge(self, app_window):
        start_x, start_y = self._get_app_window_touch_point(app_window)
        end_x = self.x + self.width
        end_y = start_y
        self.pointing_device.drag(start_x, start_y, end_x, end_y, rate=3)

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

    def is_app_visible(self, app_window):
        visible_apps = self.get_app_window_names(include_off_screen=False)[-3:]
        return app_window.objectName in visible_apps

    def swipe_app_into_view(self, app_window):
        self.swipe_to_top()
        apps = self.get_app_window_names()
        if app_window.objectName not in apps:
            raise StateNotFoundError
        while not self.is_app_visible(app_window):
            self.swipe_top_app_from_view()

    def swipe_to_top(self):
        flickable = self.select_single(
                'QQuickFlickable', objectName='spreadView')
        while not flickable.atXEnd:
            self._swipe_from_right()
            flickable.moving.wait_for(False)

    def swipe_top_app_from_view(self):
        apps = self.get_all_app_windows(include_off_screen=False)
        app_count = len(apps)
        if app_count > 2:
            self._swipe_from_app_to_right_edge(apps[-1])
        else:
            logger.warn('Cannot swipe away top app, only {} apps '
                   'displayed'.format(app_count))

    def switch_to_app(self, app_name):
        """ :parap app_name: the app id of the app to switch to """
        app = self._get_app_window(app_name)
        self.swipe_app_into_view(app)
        self._press_app(app)

