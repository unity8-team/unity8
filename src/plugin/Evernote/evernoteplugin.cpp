/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "evernoteplugin.h"

#include "evernoteconnection.h"
#include "userstore.h"
#include "notesstore.h"
#include "notes.h"
#include "notebooks.h"
#include "note.h"
#include "resource.h"
#include "notebook.h"
#include "resourceimageprovider.h"

#include <QtQml>

static QObject* userStoreProvider(QQmlEngine* /* engine */, QJSEngine* /* scriptEngine */)
{
    return UserStore::instance();
}

static QObject* notesStoreProvider(QQmlEngine* /* engine */, QJSEngine* /* scriptEngine */)
{
    return NotesStore::instance();
}

static QObject* connectionProvider(QQmlEngine* /* engine */, QJSEngine* /* scriptEngine */)
{
    return EvernoteConnection::instance();
}

void EvernotePlugin::registerTypes(const char *uri)
{
    qmlRegisterSingletonType<UserStore>("Evernote", 0, 1, "UserStore", userStoreProvider);
    qmlRegisterSingletonType<NotesStore>("Evernote", 0, 1, "NotesStore", notesStoreProvider);
    qmlRegisterSingletonType<EvernoteConnection>("Evernote", 0, 1, "EvernoteConnection", connectionProvider);

    qmlRegisterType<Notes>("Evernote", 0, 1, "Notes");
    qmlRegisterType<Notebooks>("Evernote", 0, 1, "Notebooks");
    qmlRegisterUncreatableType<Note>("Evernote", 0, 1, "Note", "Cannot create Notes in QML. Use NotesStore.createNote() instead.");
    qmlRegisterUncreatableType<Notebook>("Evernote", 0, 1, "Notebook", "Cannot create Notes in QML. Use NotesStore.createNotebook() instead.");
    qmlRegisterUncreatableType<Resource>("Evernote", 0, 1, "Resource", "Cannot create Resources. Use Note.attachFile() instead.");
}

void EvernotePlugin::initializeEngine(QQmlEngine *engine, const char *uri)
{
    engine->addImageProvider("resource", new ResourceImageProvider);
}
