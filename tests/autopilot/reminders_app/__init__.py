# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-

"""Ubuntu Touch App autopilot tests."""

from os import remove
import os.path
from tempfile import mktemp
import subprocess

from autopilot.input import Mouse, Touch, Pointer
from autopilot.matchers import Eventually
from autopilot.platform import model
from testtools.matchers import Is, Not, Equals
from autopilot.testcase import AutopilotTestCase

def get_module_include_path():
    return os.path.abspath(
        os.path.join(
            os.path.dirname(__file__),
            '..',
            '..',
            '..',
            '..',
            'modules')
        )


class UbuntuTouchAppTestCase(AutopilotTestCase):
    """A common test case class that provides several useful methods for the tests."""

    if model() == 'Desktop':
        scenarios = [
        ('with mouse', dict(input_device_class=Mouse))
        ]
    else:
        scenarios = [
        ('with touch', dict(input_device_class=Touch))
        ]

    @property
    def main_window(self):
        return MainWindow(self.app)


    def setUp(self):
        self.pointing_device = Pointer(self.input_device_class.create())
        super(UbuntuTouchAppTestCase, self).setUp()
        self.launch_test_qml()


    def launch_test_qml(self):
        # If the test class has defined a 'test_qml' class attribute then we
        # write it to disk and launch it inside the QML Scene. If not, then we
        # silently do nothing (presumably the test has something else planned).
        arch = subprocess.check_output(["dpkg-architecture",
        "-qDEB_HOST_MULTIARCH"]).strip()
        if hasattr(self, 'test_qml') and isinstance(self.test_qml, basestring):
            qml_path = mktemp(suffix='.qml')
            open(qml_path, 'w').write(self.test_qml)
            self.addCleanup(remove, qml_path)

            self.app = self.launch_test_application(
                "/usr/lib/" + arch + "/qt5/bin/qmlscene",
                "-I", get_module_include_path(),
                qml_path,
                app_type='qt')

        if hasattr(self, 'test_qml_file') and isinstance(self.test_qml_file, basestring):
            qml_path = self.test_qml_file
            self.app = self.launch_test_application(
                "/usr/lib/" + arch + "/qt5/bin/qmlscene",
                "-I", get_module_include_path(),
                qml_path,
                app_type='qt')

        self.assertThat(self.get_qml_view().visible, Eventually(Equals(True)))


    def get_qml_view(self):
        """Get the main QML view"""

        return self.app.select_single("QQuickView")

    def get_mainview(self):
        """Get the QML MainView"""

        mainView = self.app.select_single("MainView")
        self.assertThat(mainView, Not(Is(None)))
        return mainView


    def get_object(self,objectName):
        """Get a object based on the objectName"""

        obj = self.app.select_single(objectName=objectName)
        self.assertThat(obj, Not(Is(None)))
        return obj


    def mouse_click(self,objectName):
        """Move mouse on top of the object and click on it"""

        obj = self.get_object(objectName)
        self.pointing_device.move_to_object(obj)
        self.pointing_device.click()


    def mouse_press(self,objectName):
        """Move mouse on top of the object and press mouse button (without releasing it)"""

        obj = self.get_object(objectName)
        self.pointing_device.move_to_object(obj)
        self.pointing_device.press()


    def mouse_release(self):
        """Release mouse button"""

        self.pointing_device.release()     


    def type_string(self, string):
        """Type a string with keyboard"""

        self.keyboard.type(string)


    def type_key(self, key):
        """Type a single key with keyboard"""

        self.keyboard.key(key)
