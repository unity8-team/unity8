/*
 * Copyright: 2015 Canonical, Ltd
 *
 * This file is part of reminders
 *
 * reminders is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 *          Riccardo Padovani <rpadovani@ubuntu.com>
 */

#include "logging.h"

#include <QLoggingCategory>

Q_LOGGING_CATEGORY(dcNotesStore, "NotesStore")
Q_LOGGING_CATEGORY(dcJobQueue,"JobQueue")
Q_LOGGING_CATEGORY(dcConnection,"Connection")
Q_LOGGING_CATEGORY(dcSync,"Sync")
Q_LOGGING_CATEGORY(dcStorage,"Storage")
Q_LOGGING_CATEGORY(dcEnml,"Enml")
Q_LOGGING_CATEGORY(dcOrganizer,"Organizer")
