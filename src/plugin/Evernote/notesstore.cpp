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

#include "notesstore.h"
#include "evernoteconnection.h"
#include "notebooks.h"
#include "notebook.h"
#include "note.h"
#include "utils/html2enmlconverter.h"

#include "jobs/fetchnotesjob.h"
#include "jobs/fetchnotebooksjob.h"
#include "jobs/fetchnotejob.h"
#include "jobs/createnotejob.h"
#include "jobs/savenotejob.h"
#include "jobs/deletenotejob.h"

#include <QDebug>

NotesStore* NotesStore::s_instance = 0;

NotesStore::NotesStore(QObject *parent) :
    QObject(parent)
{
    connect(EvernoteConnection::instance(), &EvernoteConnection::tokenChanged, this, &NotesStore::refreshNotebooks);
    connect(EvernoteConnection::instance(), SIGNAL(tokenChanged()), this, SLOT(refreshNotes()));

    qRegisterMetaType<EvernoteConnection::ErrorCode>("EvernoteConnection::ErrorCode");
    qRegisterMetaType<evernote::edam::NotesMetadataList>("evernote::edam::NotesMetadataList");
    qRegisterMetaType<evernote::edam::Note>("evernote::edam::Note");
    qRegisterMetaType<std::vector<evernote::edam::Notebook> >("std::vector<evernote::edam::Notebook>");

}

NotesStore *NotesStore::instance()
{
    if (!s_instance) {
        s_instance = new NotesStore();
    }
    return s_instance;
}

NotesStore::~NotesStore()
{
}

QList<Note*> NotesStore::notes() const
{
    return m_notes.values();
}

Note *NotesStore::note(const QString &guid)
{
    return m_notes.value(guid);
}

QList<Notebook *> NotesStore::notebooks() const
{
    return m_notebooks.values();
}

Notebook *NotesStore::notebook(const QString &guid)
{
    return m_notebooks.value(guid);
}

void NotesStore::refreshNotes(const QString &filterNotebookGuid)
{
    FetchNotesJob *job = new FetchNotesJob(filterNotebookGuid);
    connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Failed to fetch notes list:" << errorMessage;
        return;
    }

    for (int i = 0; i < results.notes.size(); ++i) {
        evernote::edam::NoteMetadata result = results.notes.at(i);
        Note *note = m_notes.value(QString::fromStdString(result.guid));
        if (note) {
            note->setTitle(QString::fromStdString(result.title));
            note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
            emit noteChanged(note->guid());
        } else {
            note = new Note(QString::fromStdString(result.guid), this);
            note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
            note->setTitle(QString::fromStdString(result.title));
            m_notes.insert(note->guid(), note);
            emit noteAdded(note->guid());
        }
    }
}

void NotesStore::refreshNoteContent(const QString &guid)
{
    FetchNoteJob *job = new FetchNoteJob(guid, this);
    connect(job, &FetchNoteJob::resultReady, this, &NotesStore::fetchNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching note:" << errorMessage;
        return;
    }

    Note *note = m_notes.value(QString::fromStdString(result.guid));
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setContent(QString::fromStdString(result.content));
    emit noteChanged(note->guid());
}

void NotesStore::refreshNotebooks()
{
    FetchNotebooksJob *job = new FetchNotebooksJob();
    connect(job, &FetchNotebooksJob::jobDone, this, &NotesStore::fetchNotebooksJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching notebooks:" << errorMessage;
        return;
    }

    for (int i = 0; i < results.size(); ++i) {
        evernote::edam::Notebook result = results.at(i);
        Notebook *notebook = m_notebooks.value(QString::fromStdString(result.guid));
        if (notebook) {
            qDebug() << "got notebook update";
            notebook->setName(QString::fromStdString(result.name));
            emit notebookChanged(notebook->guid());
        } else {
            notebook = new Notebook(QString::fromStdString(result.guid), this);
            notebook->setName(QString::fromStdString(result.name));
            m_notebooks.insert(notebook->guid(), notebook);
            emit notebookAdded(notebook->guid());
            qDebug() << "got new notebook" << notebook->guid();
        }
    }
}

void NotesStore::createNote(const QString &title, const QString &notebookGuid, const QString &content)
{
    CreateNoteJob *job = new CreateNoteJob(title, notebookGuid, content);
    connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error creating note:" << errorMessage;
        return;
    }

    Note *note = new Note(QString::fromStdString(result.guid));
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setContent(QString::fromStdString(result.content));

    m_notes.insert(note->guid(), note);
    noteAdded(note->guid());
}

void NotesStore::saveNote(const QString &guid)
{
    Note *note = m_notes.value(guid);

    QString enml = Html2EnmlConverter::html2enml(note->content());
    note->setContent(enml);

    SaveNoteJob *job = new SaveNoteJob(note, this);
    connect(job, &SaveNoteJob::jobDone, this, &NotesStore::saveNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::saveNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "error saving note" << errorMessage;
        return;
    }

    Note *note = m_notes.value(QString::fromStdString(result.guid));
    if (note) {
        note->setTitle(QString::fromStdString(result.title));
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));

        emit noteChanged(note->guid());
    }
}

void NotesStore::deleteNote(const QString &guid)
{
    DeleteNoteJob *job = new DeleteNoteJob(guid, this);
    connect(job, &DeleteNoteJob::jobDone, this, &NotesStore::deleteNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Cannot delete note:" << errorMessage;
        return;
    }
    emit noteRemoved(guid);
    m_notes.take(guid)->deleteLater();
}
