from unity8 import (
    launcher as launcher_helpers,
    phone_stage,
    wait_until
)

from unity8.process_helpers import unlock_unity

from unity8.shell import (
    tests
)

APP_ID_DASH = 'unity8-dash'
APP_ID_DIALER = 'dialer-app'
APP_ID_WEBBROWSER = 'webbrowser-app'

class AppSwitcherTestCase(tests.UnityTestCase):

    def _get_window_name(self, app_name):
        """
        :return: App window name for specified app name.
        """
        return 'appWindow_' + app_name

    def _get_window_names(self, app_names):
        """
        :return: a list of window names for specified list of app names.
        """
        return [self._get_window_name(app_name) for app_name in app_names]

    def _launch_applications_and_switcher(self):
        """
        Launch test applications and open the task switcher
        :return: PhoneStage task switcher object.
        """

        # FIXME Launch more apps. Currently these are the only
        # ones I can get to work
        self.main_window.launch_application(APP_ID_DIALER)
        self.main_window.launch_application(APP_ID_WEBBROWSER)
        stage = self.main_window.swipe_to_show_app_switcher()
        stage.swipe_to_top()
        apps = stage.get_app_window_names()
        expected_apps = [APP_ID_WEBBROWSER, APP_ID_DIALER, APP_ID_DASH]
        expected_names = self._get_window_names(expected_apps)
        self.assertEqual(expected_names, apps)
        return self.main_window.swipe_to_show_app_switcher()

    def _switch_to_app(self, stage, app_name):
        stage.switch_to_app(app_name)
        self.assertTrue(wait_until(
            lambda: self.main_window.get_current_focused_app_id() == app_name))

    def test_app_selection(self):
        """
        Launch applications and check that it is possible to switch focus
        back to them using the task switcher.
        """
        self.launch_unity()
        unlock_unity()
        stage = self._launch_applications_and_switcher()
        self._switch_to_app(stage, APP_ID_DIALER)

