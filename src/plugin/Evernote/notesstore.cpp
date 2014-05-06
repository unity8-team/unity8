/*
 * Copyright: 2013 Canonical, Ltd
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
 */

#include "notesstore.h"
#include "evernoteconnection.h"
#include "notebooks.h"
#include "notebook.h"
#include "note.h"
#include "utils/enmldocument.h"

#include "jobs/fetchnotesjob.h"
#include "jobs/fetchnotebooksjob.h"
#include "jobs/fetchnotejob.h"
#include "jobs/createnotejob.h"
#include "jobs/savenotejob.h"
#include "jobs/deletenotejob.h"
#include "jobs/createnotebookjob.h"
#include "jobs/expungenotebookjob.h"

#include <QImage>
#include <QDebug>

NotesStore* NotesStore::s_instance = 0;

NotesStore::NotesStore(QObject *parent) :
    QAbstractListModel(parent),
    m_loading(false),
    m_notebooksLoading(false)
{
    connect(EvernoteConnection::instance(), &EvernoteConnection::tokenChanged, this, &NotesStore::refreshNotebooks);
    connect(EvernoteConnection::instance(), SIGNAL(tokenChanged()), this, SLOT(refreshNotes()));

    qRegisterMetaType<evernote::edam::NotesMetadataList>("evernote::edam::NotesMetadataList");
    qRegisterMetaType<evernote::edam::Note>("evernote::edam::Note");
    qRegisterMetaType<std::vector<evernote::edam::Notebook> >("std::vector<evernote::edam::Notebook>");
    qRegisterMetaType<evernote::edam::Notebook>("evernote::edam::Notebook");

}

NotesStore *NotesStore::instance()
{
    if (!s_instance) {
        s_instance = new NotesStore();
    }
    return s_instance;
}

bool NotesStore::loading() const
{
    return m_loading;
}

bool NotesStore::notebooksLoading() const
{
    return m_notebooksLoading;
}

QString NotesStore::error() const
{
    return m_error;
}

QString NotesStore::notebooksError() const
{
    return m_notebooksError;
}

int NotesStore::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_notes.count();
}

QVariant NotesStore::data(const QModelIndex &index, int role) const
{
    switch (role) {
    case RoleGuid:
        return m_notes.at(index.row())->guid();
    case RoleNotebookGuid:
        return m_notes.at(index.row())->notebookGuid();
    case RoleCreated:
        return m_notes.at(index.row())->created();
    case RoleTitle:
        return m_notes.at(index.row())->title();
    case RoleReminder:
        return m_notes.at(index.row())->reminder();
    case RoleReminderTime:
        return m_notes.at(index.row())->reminderTime();
    case RoleReminderTimeString:
        return m_notes.at(index.row())->reminderTimeString();
    case RoleReminderDone:
        return m_notes.at(index.row())->reminderDone();
    case RoleReminderDoneTime:
        return m_notes.at(index.row())->reminderDoneTime();
    case RoleEnmlContent:
        return m_notes.at(index.row())->enmlContent();
    case RoleHtmlContent:
        return m_notes.at(index.row())->htmlContent();
    case RoleRichTextContent:
        return m_notes.at(index.row())->richTextContent();
    case RolePlaintextContent:
        return m_notes.at(index.row())->plaintextContent();
    case RoleResourceUrls:
        return m_notes.at(index.row())->resourceUrls();
    }
    return QVariant();
}

QHash<int, QByteArray> NotesStore::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleNotebookGuid, "notebookGuid");
    roles.insert(RoleCreated, "created");
    roles.insert(RoleTitle, "title");
    roles.insert(RoleReminder, "reminder");
    roles.insert(RoleReminderTime, "reminderTime");
    roles.insert(RoleReminderTimeString, "reminderTimeString");
    roles.insert(RoleReminderDone, "reminderDone");
    roles.insert(RoleReminderDoneTime, "reminderDoneTime");
    roles.insert(RoleEnmlContent, "enmlContent");
    roles.insert(RoleRichTextContent, "richTextContent");
    roles.insert(RoleHtmlContent, "htmlContent");
    roles.insert(RolePlaintextContent, "plaintextContent");
    roles.insert(RoleResourceUrls, "resourceUrls");
    return roles;
}

NotesStore::~NotesStore()
{
}

QList<Note*> NotesStore::notes() const
{
    return m_notes;
}

Note *NotesStore::note(const QString &guid)
{
    return m_notesHash.value(guid);
}

QList<Notebook *> NotesStore::notebooks() const
{
    return m_notebooks;
}

Notebook *NotesStore::notebook(const QString &guid)
{
    return m_notebooksHash.value(guid);
}

void NotesStore::createNotebook(const QString &name)
{
    CreateNotebookJob *job = new CreateNotebookJob(name);
    connect(job, &CreateNotebookJob::jobDone, this, &NotesStore::createNotebookJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::expungeNotebook(const QString &guid)
{
    ExpungeNotebookJob *job = new ExpungeNotebookJob(guid);
    connect(job, &ExpungeNotebookJob::jobDone, this, &NotesStore::expungeNotebookJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::refreshNotes(const QString &filterNotebookGuid)
{
    if (EvernoteConnection::instance()->token().isEmpty()) {
        beginResetModel();
        foreach (Note *note, m_notes) {
            emit noteRemoved(note->guid(), note->notebookGuid());
            note->deleteLater();
        }
        m_notes.clear();
        endResetModel();
    } else {
        m_loading = true;
        emit loadingChanged();
        FetchNotesJob *job = new FetchNotesJob(filterNotebookGuid);
        connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results)
{
    m_loading = false;
    emit loadingChanged();

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Failed to fetch notes list:" << errorMessage;
        m_error = tr("Error refreshing notes: %1").arg(errorMessage);
        emit errorChanged();
        return;
    }
    if (!m_error.isEmpty()) {
        m_error.clear();
        emit errorChanged();
    }

    for (unsigned int i = 0; i < results.notes.size(); ++i) {
        evernote::edam::NoteMetadata result = results.notes.at(i);
        Note *note = m_notesHash.value(QString::fromStdString(result.guid));
        bool newNote = note == 0;
        if (newNote) {
            QString guid = QString::fromStdString(result.guid);
            QDateTime created = QDateTime::fromMSecsSinceEpoch(result.created);
            note = new Note(guid, created, this);
        }

        note->setTitle(QString::fromStdString(result.title));
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
        note->setReminderOrder(result.attributes.reminderOrder);

        if (!results.searchedWords.empty()) {
            note->setIsSearchResult(true);
        }

        QDateTime reminderTime;
        if (result.attributes.reminderTime > 0) {
            reminderTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderTime);
        }
        note->setReminderTime(reminderTime);
        QDateTime reminderDoneTime;
        if (result.attributes.reminderDoneTime > 0) {
            reminderDoneTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderDoneTime);
        }
        note->setReminderDoneTime(reminderDoneTime);

        if (newNote) {
            beginInsertRows(QModelIndex(), m_notes.count(), m_notes.count());
            m_notesHash.insert(note->guid(), note);
            m_notes.append(note);
            endInsertRows();
            emit noteAdded(note->guid(), note->notebookGuid());
        } else {
            QModelIndex noteIndex = index(m_notes.indexOf(note));
            emit dataChanged(noteIndex, noteIndex);
            emit noteChanged(note->guid(), note->notebookGuid());
        }
    }
}

void NotesStore::refreshNoteContent(const QString &guid, bool withResourceContent)
{
    Note *note = m_notesHash.value(guid);
    if (note) {
        note->setLoading(true);
    }

    FetchNoteJob *job = new FetchNoteJob(guid, withResourceContent, this);
    connect(job, &FetchNoteJob::resultReady, this, &NotesStore::fetchNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result, bool withResourceContent)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching note:" << errorMessage;
        return;
    }

    Note *note = m_notesHash.value(QString::fromStdString(result.guid));
    if (!note) {
        qWarning() << "can't find note for this update... ignoring...";
        return;
    }
    note->setLoading(false);
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));

    // Notes are fetched without resources by default. if we discover one or more resources where we don't have
    // data in the cache, just refresh the note again with resource data.
    bool refreshWithResourceData = false;

    // Resources need to be set before the content because otherwise the image provider won't find them when the content is updated in the ui
    for (unsigned int i = 0; i < result.resources.size(); ++i) {

        evernote::edam::Resource resource = result.resources.at(i);

        QString hash = QByteArray::fromRawData(resource.data.bodyHash.c_str(), resource.data.bodyHash.length()).toHex();
        QString fileName = QString::fromStdString(resource.attributes.fileName);
        QString mime = QString::fromStdString(resource.mime);

        if (withResourceContent) {
            QByteArray resourceData = QByteArray(resource.data.body.data(), resource.data.size);
            note->addResource(resourceData, hash, fileName, mime);
        } else if (Resource::isCached(hash)) {
            note->addResource(QByteArray(), hash, fileName, mime);
        } else {
            refreshWithResourceData = true;
        }
    }

    note->setEnmlContent(QString::fromStdString(result.content));
    note->setReminderOrder(result.attributes.reminderOrder);
    QDateTime reminderTime;
    if (result.attributes.reminderTime > 0) {
        reminderTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderTime);
    }
    note->setReminderTime(reminderTime);
    QDateTime reminderDoneTime;
    if (result.attributes.reminderDoneTime > 0) {
        reminderDoneTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderDoneTime);
    }
    note->setReminderDoneTime(reminderDoneTime);
    emit noteChanged(note->guid(), note->notebookGuid());

    QModelIndex noteIndex = index(m_notes.indexOf(note));
    emit dataChanged(noteIndex, noteIndex);

    if (refreshWithResourceData) {
        refreshNoteContent(note->guid(), true);
    }
}

void NotesStore::refreshNotebooks()
{
    if (EvernoteConnection::instance()->token().isEmpty()) {
        foreach (Notebook *notebook, m_notebooks) {
            emit notebookRemoved(notebook->guid());
            notebook->deleteLater();
        }
        m_notebooks.clear();
    } else {
        m_notebooksLoading = true;
        emit notebooksLoadingChanged();
        FetchNotebooksJob *job = new FetchNotebooksJob();
        connect(job, &FetchNotebooksJob::jobDone, this, &NotesStore::fetchNotebooksJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results)
{
    m_notebooksLoading = false;
    emit notebooksLoadingChanged();

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching notebooks:" << errorMessage;
        m_notebooksError = tr("Error refreshing notebooks: %1").arg(errorMessage);
        emit notebooksErrorChanged();
        return;
    }
    if (!m_notebooksError.isEmpty()) {
        m_notebooksError.clear();
        emit notebooksErrorChanged();
    }

    for (unsigned int i = 0; i < results.size(); ++i) {
        evernote::edam::Notebook result = results.at(i);
        Notebook *notebook = m_notebooksHash.value(QString::fromStdString(result.guid));
        bool newNoteNotebook = notebook == 0;
        if (newNoteNotebook) {
            notebook = new Notebook(QString::fromStdString(result.guid), this);
        }
        notebook->setName(QString::fromStdString(result.name));
        notebook->setPublished(result.published);

        if (newNoteNotebook) {
            m_notebooksHash.insert(notebook->guid(), notebook);
            m_notebooks.append(notebook);
            emit notebookAdded(notebook->guid());
        } else {
            emit notebookChanged(notebook->guid());
        }
    }
}

void NotesStore::createNote(const QString &title, const QString &notebookGuid, const QString &richTextContent)
{
    EnmlDocument enmlDoc;
    enmlDoc.setRichText(richTextContent);
    createNote(title, notebookGuid, enmlDoc);
}

void NotesStore::createNote(const QString &title, const QString &notebookGuid, const EnmlDocument &content)
{
    CreateNoteJob *job = new CreateNoteJob(title, notebookGuid, content.enml());
    connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error creating note:" << errorMessage;
        return;
    }

    QString guid = QString::fromStdString(result.guid);
    QDateTime created = QDateTime::fromMSecsSinceEpoch(result.created);
    Note *note = new Note(guid, created, this);
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setEnmlContent(QString::fromStdString(result.content));

    beginInsertRows(QModelIndex(), m_notes.count(), m_notes.count());
    m_notesHash.insert(note->guid(), note);
    m_notes.append(note);
    endInsertRows();

    emit noteAdded(note->guid(), note->notebookGuid());
    emit noteCreated(note->guid(), note->notebookGuid());
}

void NotesStore::saveNote(const QString &guid)
{
    Note *note = m_notesHash.value(guid);
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

    Note *note = m_notesHash.value(QString::fromStdString(result.guid));
    if (note) {
        note->setTitle(QString::fromStdString(result.title));
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));

        emit noteChanged(note->guid(), note->notebookGuid());

        QModelIndex noteIndex = index(m_notes.indexOf(note));
        emit dataChanged(noteIndex, noteIndex);
    }
}

void NotesStore::deleteNote(const QString &guid)
{
    DeleteNoteJob *job = new DeleteNoteJob(guid, this);
    connect(job, &DeleteNoteJob::jobDone, this, &NotesStore::deleteNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::findNotes(const QString &searchWords)
{
    foreach (Note *note, m_notes) {
        note->setIsSearchResult(false);
    }
    emit dataChanged(index(0), index(m_notes.count()), QVector<int>() << RoleIsSearchResult);

    FetchNotesJob *job = new FetchNotesJob(QString(), searchWords);
    connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Cannot delete note:" << errorMessage;
        return;
    }
    Note *note = m_notesHash.value(guid);
    int noteIndex = m_notes.indexOf(note);

    emit noteRemoved(guid, note->notebookGuid());

    beginRemoveRows(QModelIndex(), noteIndex, noteIndex);
    m_notes.takeAt(noteIndex);
    m_notesHash.take(guid)->deleteLater();
    endRemoveRows();
}

void NotesStore::createNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Notebook &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error creating notebook:" << errorMessage;
        return;
    }
    Notebook *notebook = new Notebook(QString::fromStdString(result.guid));
    notebook->setName(QString::fromStdString(result.name));
    m_notebooks.append(notebook);
    m_notebooksHash.insert(notebook->guid(), notebook);
    emit notebookAdded(notebook->guid());
}

void NotesStore::expungeNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error expunging notebook:" << errorMessage;
        return;
    }
    emit notebookRemoved(guid);
    Notebook *notebook = m_notebooksHash.take(guid);
    m_notebooks.removeAll(notebook);
    notebook->deleteLater();
}
