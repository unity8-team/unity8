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

#ifndef LOGGING_H
#define LOGGING_H

#include <QLoggingCategory>

Q_DECLARE_LOGGING_CATEGORY(dcNotesStore)
Q_DECLARE_LOGGING_CATEGORY(dcJobQueue)
Q_DECLARE_LOGGING_CATEGORY(dcConnection)
Q_DECLARE_LOGGING_CATEGORY(dcSync)
Q_DECLARE_LOGGING_CATEGORY(dcEnml)
Q_DECLARE_LOGGING_CATEGORY(dcOrganizer)

#endif
