# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Indicators Autopilot Test Suite
# Copyright (C) 2015 Canonical
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

from testscenarios import multiply_scenarios

from unity8 import (
    fixture_setup,
    indicators,
)
from unity8.indicators import tests

from autopilot.matchers import Eventually
from testtools.matchers import Equals, NotEquals


class TestIndicatorBaseTestCase(tests.IndicatorTestCase):

    # QA Minor: A comment stating why this is only using a single scenario
    # would be clearer
    scenarios = [tests.IndicatorTestCase.device_emulation_scenarios[0]]

    def setUp(self):
        # QA: Outdated, with python3 this can be super().setUp()
        super(TestIndicatorBaseTestCase, self).setUp()

        # QA Prob: The use of self.action_delay in such a way (Expecting it to
        # be dynamically set before setUp is called, in this instance using
        # scenarios) isn't very well defined and makes it possible to use the
        # class incorrectly (i.e. it's not obvious to authors subclassing this
        # that they need to set a member variable called action_delay.
        #
        # QA Suggestion: I would suggest making action_delay an argument to
        # setUp. This way it can default to a sensible value as well and now
        # being obvious that it's there (and not relying on it to magically be
        # set.)
        # def setUp(self, action_delay):
        #    ...
        #    self.launch_indicator_service(action_delay)
        # ...

        self.launch_indicator_service()

        # wait for the indicator to appear in unity
        self.indicator = indicators.TestIndicator(self.main_window)
        self.assertThat(
            self.indicator.is_indicator_icon_visible(),
            Eventually(Equals(True), timeout=20)
        )
        self.indicator_page = self.indicator.open()

    def launch_indicator_service(self):
        launch_service_fixture = \
            fixture_setup.LaunchMockIndicatorService(self.action_delay)
        self.useFixture(launch_service_fixture)


class TestServerValueUpdate(TestIndicatorBaseTestCase):

    """Test that an action causes the server to update"""

    time_scenarios = [
        ('Low', {'action_delay': 0}),
        ('Medium', {'action_delay': 2500}),
        ('High', {'action_delay': 8000}),
    ]
    scenarios = multiply_scenarios(
        time_scenarios,
        TestIndicatorBaseTestCase.scenarios
    )

    # QA: with the suggested enhancement this would need something like:
    # def setUp(self):
    #     super().setUp(self.action_delay)

    # QA Query: How come there is a need for an extended timeout in all the
    # assertThat calls? A comment stating why clarifies for future authors.

    def test_switch_reaches_server_value(self):
        switch = self.indicator_page.get_switcher()
        switch_menu = self.indicator_page.get_switch_menu()

        switch.change_state()

        self.assertThat(
            switch_menu.serverChecked,
            Eventually(Equals(switch.checked), timeout=20)
        )

    def test_slider_reaches_server_value(self):
        # QA minor: Needs docstring describing what this test is doing/expects.
        slider = self.indicator_page.get_slider()
        slider_menu = self.indicator_page.get_slider_menu()

        old_value = slider.value
        slider.slide_left()

        self.assertThat(
            slider_menu.serverValue,
            Eventually(NotEquals(old_value), timeout=20)
        )

        self.assertThat(
            slider_menu.serverValue,
            Eventually(Equals(slider.value), timeout=20)
        )


class TestBuffering(TestIndicatorBaseTestCase):

    """Test that switching multiple times will buffer activations

    See https://bugs.launchpad.net/ubuntu/+source/unity8/+bug/1390136 .
    """
    # QA: As per above suggestion, the use of this becomes clearer.
    action_delay = 2500

    def test_switch_buffers_actvations(self):
        # QA: This should have a docstring clarifying what the test intends to
        # check.
        # For instance; Is this checking that the state really quickly does not
        # check the UI but the server end should change back and forth?

        # QA: Due to dealing with timing an autopilot test might not be the
        # best level to test with. (the docstring mentioned above would help
        # clarify this point.)

        switch = self.indicator_page.get_switcher()
        switch.change_state()
        intermediate_value = switch.checked

        # will buffer change until it receives the change from server
        switch.change_state()
        final_value = switch.checked

        # backend will respond to first switch.
        switch_menu = self.indicator_page.get_switch_menu()
        self.assertThat(
            switch_menu.serverChecked,
            Eventually(Equals(intermediate_value), timeout=20)
        )
        # The buffered activation should have gone to server now.

        # front-end should not change as a result of server update
        # while it is buffered
        self.assertThat(
            switch.checked,
            Equals(final_value)
        )

        # server will respond to the second activate
        self.assertThat(
            switch_menu.serverChecked,
            Eventually(Equals(final_value), timeout=20)
        )

        # QA Query: Is this check not the same as the one above? Checking
        # switch_menu.serverChecked against final_value (which is
        # switch.checked) is the same as checking:
        # switch.checked (which is final_value) against
        # switch_menu.serverChecked

        # make sure we've got the server value set.
        self.assertThat(
            switch.checked,
            Equals(switch_menu.serverChecked)
        )

    def test_slider_buffers_activations(self):
        # QA: Docstring needed.

        slider = self.indicator_page.get_slider()
        original_value = slider.value
        slider.slide_left()

        # will buffer change until it receives the change from server
        slider.slide_right()
        final_value = slider.value

        # backend will respond to first slider. Since it's a live slider
        # it'll probably be a random value along the slide.
        slider_menu = self.indicator_page.get_slider_menu()
        self.assertThat(
            slider_menu.serverValue,
            Eventually(NotEquals(original_value), timeout=20)
        )
        # It wont yet have reached the final value due to the buffering
        # Second activate should have gone out by now
        self.assertThat(
            slider_menu.serverValue,
            NotEquals(final_value)
        )

        # front-end should not change as a result of server update
        # while it is buffered
        self.assertThat(
            slider.value,
            Equals(final_value)
        )

        # QA: It appears that these 2 asserts are checking the same thing, just
        # using different variable names to do so.
        # (Same as mentioned above).
        # server will respond to the second activate
        self.assertThat(
            slider_menu.serverValue,
            Eventually(Equals(final_value), timeout=20)
        )

        # make sure we've got the server value set.
        self.assertThat(
            slider.value,
            Equals(slider_menu.serverValue)
        )


class TestClientRevertsToServerValue(TestIndicatorBaseTestCase):

    """Test that an action which does not respond in time will revert
    to original value if not actioned in time.

    See https://bugs.launchpad.net/ubuntu/+source/unity8/+bug/1390136 .
    """

    # QA: The use of action_delay would either be removed (if a default is
    # used) or more obvious (as it's needed to be passed to setUp()).
    action_delay = -1  # never action.

    # QA: Autopilot tests aren't the best fit for tests that depend on timing.
    # QA Suggestion: Make these tests at a better level for example <link to
    # documentation re: better level of testing.>
    def test_switch_reverts_on_late_response(self):

        switch = self.indicator_page.get_switcher()
        switch_menu = self.indicator_page.get_switch_menu()

        original_value = switch.checked
        switch.change_state()

        # switch should revert to original value after 5 seconds
        # (30 seconds in real usage)
        self.assertThat(
            switch.checked,
            Eventually(Equals(original_value), timeout=20)
        )

        # make sure we've got the server value set.
        self.assertThat(
            switch.checked,
            Equals(switch_menu.serverChecked)
        )

    def test_slider_reverts_on_late_response(self):

        slider = self.indicator_page.get_slider()
        slider_menu = self.indicator_page.get_slider_menu()

        original_value = slider.value
        slider.slide_left()

        # slider should revert to original value after 5 seconds
        # (30 seconds in real usage)
        self.assertThat(
            slider.value,
            Eventually(Equals(original_value), timeout=20)
        )

        # make sure we've got the server value set.
        self.assertThat(
            slider.value,
            Equals(slider_menu.serverValue)
        )
