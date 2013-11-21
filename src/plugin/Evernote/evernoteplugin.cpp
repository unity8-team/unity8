/*****************************************************************************
 * Copyright: 2013 Michael Zanetti <michael.zanetti@canonical.com>           *
 *                                                                           *
 * This project is free software: you can redistribute it and/or modify      *
 * it under the terms of the GNU General Public License as published by      *
 * the Free Software Foundation, either version 3 of the License, or         *
 * (at your option) any later version.                                       *
 *                                                                           *
 * This project is distributed in the hope that it will be useful,           *
 * but WITHOUT ANY WARRANTY; without even the implied warranty of            *
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the             *
 * GNU General Public License for more details.                              *
 *                                                                           *
 * You should have received a copy of the GNU General Public License         *
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.     *
 *                                                                           *
 ****************************************************************************/

#include "evernoteplugin.h"

#include "userstore.h"
#include "notesstore.h"
#include "notes.h"
#include "notebooks.h"

#include <QtQml>

static QObject* notesStoreProvider(QQmlEngine* /* engine */, QJSEngine* /* scriptEngine */)
{
    return NotesStore::instance();
}

void FitBitPlugin::registerTypes(const char *uri)
{
    qmlRegisterType<UserStore>("Evernote", 0, 1, "UserStore");

    qmlRegisterSingletonType<NotesStore>("Evernote", 0, 1, "NotesStore", notesStoreProvider);
    qmlRegisterType<Notes>("Evernote", 0, 1, "Notes");
    qmlRegisterType<Notebooks>("Evernote", 0, 1, "Notebooks");
}
