from unity8 import (
    launcher as launcher_helpers,
    phone_stage
)

from unity8.process_helpers import unlock_unity

from unity8.shell import (
    tests
)

class AppSwitcherTestCase(tests.UnityTestCase):

    def _launch_applications_and_switcher(self):
        """
        Launch test applications and open the task switcher
        :return: PhoneStage task switcher object.
        """

        # FIXME Launch more apps. Currently these are the only
        # ones I can get to work
        self.main_window.launch_application("dialer-app")
        self.main_window.launch_application("webbrowser-app")
        stage = self.main_window.swipe_to_show_app_switcher()

    def test_app_selection(self):
        """
        Launch applications and check that it is possible to switch focus
        back to them using the task switcher.
        """
        self.launch_unity()
        unlock_unity()
        self._launch_applications_and_switcher()
