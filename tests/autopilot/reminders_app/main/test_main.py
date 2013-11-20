# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-

"""Tests for the Hello World"""

from autopilot.matchers import Eventually
from textwrap import dedent
from testtools.matchers import Is, Not, Equals
from testtools import skip
import os
from reminders-app import UbuntuTouchAppTestCase


class GenericTests(UbuntuTouchAppTestCase):
    """Generic tests for the Hello World"""

    test_qml_file = "%s/%s.qml" % (os.path.dirname(os.path.realpath(__file__)),"../../../../reminders-app")

    def test_0_can_select_mainView(self):
        """Must be able to select the mainview."""

        mainView = self.get_mainview()
        self.assertThat(mainView.visible,Eventually(Equals(True)))


    def test_1_init_label(self):
        """Check the initial text of the label"""

        lbl = self.get_object(objectName="label")
        self.assertThat(lbl.text, Equals("Hello.."))


    def test_can_tap_button(self):
        """Must be able to tap the button"""

        lbl = self.get_object(objectName="label")
        self.mouse_click(objectName="button")
        self.assertThat(lbl.text, Eventually(Equals("..world!")))

