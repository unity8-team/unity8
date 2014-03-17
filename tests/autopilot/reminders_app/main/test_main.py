# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-

"""Tests for the Hello World"""

from autopilot.matchers import Eventually
from textwrap import dedent
from testtools.matchers import Is, Not, Equals
from testtools import skip
import os
from reminders import UbuntuTouchAppTestCase


class GenericTests(UbuntuTouchAppTestCase):
    """Generic tests for the Hello World"""

    if os.path.realpath(__file__).startswith("/usr/"):
        test_qml_file = "/usr/share/reminders/qml/reminders.qml"
    else:
        test_qml_file = "%s/%s.qml" % (os.path.dirname(os.path.realpath(__file__)),"../../../../src/app/qml/reminders")

    def test_0_can_select_mainView(self):
        """Must be able to select the mainview."""

        mainView = self.get_mainview()
        self.assertThat(mainView.visible,Eventually(Equals(True)))



