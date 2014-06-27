# -*- Mode: Python; coding: utf-8; indent-tabs-mode: nil; tab-width: 4 -*-
#
# Unity Static Pre-commit Tests
# Copyright (C) 2014 Canonical
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

import logging
import os
import subprocess

from bzrlib import branch, urlutils


logger = logging.getLogger(__name__)


def run_static_tests(
        local_branch, master_branch, old_revision_number, old_revision_id,
        future_revision_number, future_revision_id, tree_delta, future_tree):
    """Run static tests on the source code."""
    _run_python_static_tests(master_branch)


def _run_python_static_tests(master_branch):
    """Run static tests on python code."""
    if master_branch.basis_tree().has_filename('run_python_static_tests.sh'):
        os.chdir(urlutils.local_path_from_url(master_branch.base))
        print('Running the python static tests.')
        subprocess.call('./run_python_static_tests.sh')
    else:
        print('The python static tests will not be run.')


branch.Branch.hooks.install_named_hook(
    'pre_commit', run_static_tests, 'Run static tests before commit')
