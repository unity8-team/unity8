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
#include "tag.h"
#include "utils/enmldocument.h"
#include "utils/organizeradapter.h"
#include "userstore.h"
#include "logging.h"

#include "jobs/fetchnotesjob.h"
#include "jobs/fetchnotebooksjob.h"
#include "jobs/fetchnotejob.h"
#include "jobs/createnotejob.h"
#include "jobs/savenotejob.h"
#include "jobs/savenotebookjob.h"
#include "jobs/deletenotejob.h"
#include "jobs/createnotebookjob.h"
#include "jobs/expungenotebookjob.h"
#include "jobs/fetchtagsjob.h"
#include "jobs/createtagjob.h"
#include "jobs/savetagjob.h"

#include "libintl.h"

#include <QImage>
#include <QStandardPaths>
#include <QUuid>
#include <QPointer>
#include <QDir>

NotesStore* NotesStore::s_instance = 0;

NotesStore::NotesStore(QObject *parent) :
    QAbstractListModel(parent),
    m_username("@invalid "),
    m_loading(false),
    m_notebooksLoading(false),
    m_tagsLoading(false)
{
    qCDebug(dcNotesStore) << "Creating NotesStore instance.";
    connect(UserStore::instance(), &UserStore::usernameChanged, this, &NotesStore::userStoreConnected);

    qRegisterMetaType<evernote::edam::NotesMetadataList>("evernote::edam::NotesMetadataList");
    qRegisterMetaType<evernote::edam::Note>("evernote::edam::Note");
    qRegisterMetaType<std::vector<evernote::edam::Notebook> >("std::vector<evernote::edam::Notebook>");
    qRegisterMetaType<evernote::edam::Notebook>("evernote::edam::Notebook");
    qRegisterMetaType<std::vector<evernote::edam::Tag> >("std::vector<evernote::edam::Tag>");
    qRegisterMetaType<evernote::edam::Tag>("evernote::edam::Tag");

    m_organizerAdapter = new OrganizerAdapter(this);

    QDir storageDir(QStandardPaths::standardLocations(QStandardPaths::DataLocation).first());
    if (!storageDir.exists()) {
        qCDebug(dcNotesStore) << "Creating storage directory:" << storageDir.absolutePath();
        storageDir.mkpath(storageDir.absolutePath());
    }
}

NotesStore *NotesStore::instance()
{
    if (!s_instance) {
        s_instance = new NotesStore();
    }
    return s_instance;
}

QString NotesStore::username() const
{
    return m_username;
}

void NotesStore::setUsername(const QString &username)
{
    if (username.isEmpty()) {
        // We don't accept an empty username.
        return;
    }
    if (!UserStore::instance()->username().isEmpty() && username != UserStore::instance()->username()) {
        qCWarning(dcNotesStore) << "Logged in to Evernote. Can't change account manually. User EvernoteConnection to log in to another account or log out and change this manually.";
        return;
    }

    if (m_username != username) {
        m_username = username;
        emit usernameChanged();

        m_cacheFile = storageLocation() + "notes.cache";
        qCDebug(dcNotesStore) << "Initialized cacheFile:" << m_cacheFile;
        loadFromCacheFile();
    }
}

QString NotesStore::storageLocation()
{
    return QStandardPaths::standardLocations(QStandardPaths::DataLocation).first() + "/" + m_username + "/";
}

void NotesStore::userStoreConnected(const QString &username)
{
    qCDebug(dcNotesStore) << "User store connected! Using username:" << username;
    setUsername(username);

    refreshNotebooks();
    refreshTags();
    refreshNotes();
}

bool NotesStore::loading() const
{
    return m_loading;
}

bool NotesStore::notebooksLoading() const
{
    return m_notebooksLoading;
}

bool NotesStore::tagsLoading() const
{
    return m_tagsLoading;
}

QString NotesStore::error() const
{
    return m_errorQueue.count() > 0 ? m_errorQueue.first() : QString();
}

int NotesStore::count() const
{
    return rowCount();
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
    case RoleCreatedString:
        return m_notes.at(index.row())->createdString();
    case RoleUpdated:
        return m_notes.at(index.row())->updated();
    case RoleUpdatedString:
        return m_notes.at(index.row())->updatedString();
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
    case RoleTagline:
        return m_notes.at(index.row())->tagline();
    case RoleResourceUrls:
        return m_notes.at(index.row())->resourceUrls();
    case RoleReminderSorting:
        // done reminders get +1000000000000 (this will break sorting in year 2286 :P)
        return QVariant::fromValue(m_notes.at(index.row())->reminderTime().toMSecsSinceEpoch() +
                (m_notes.at(index.row())->reminderDone() ? 10000000000000 : 0));
    case RoleTagGuids:
        return m_notes.at(index.row())->tagGuids();
    case RoleDeleted:
        return m_notes.at(index.row())->deleted();
    case RoleSynced:
        return m_notes.at(index.row())->synced();
    case RoleLoading:
        return m_notes.at(index.row())->loading();
    case RoleSyncError:
        return m_notes.at(index.row())->syncError();
    case RoleConflicting:
        return m_notes.at(index.row())->conflicting();
    }
    return QVariant();
}

QHash<int, QByteArray> NotesStore::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleNotebookGuid, "notebookGuid");
    roles.insert(RoleCreated, "created");
    roles.insert(RoleCreatedString, "createdString");
    roles.insert(RoleUpdated, "updated");
    roles.insert(RoleUpdatedString, "updatedString");
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
    roles.insert(RoleTagline, "tagline");
    roles.insert(RoleResourceUrls, "resourceUrls");
    roles.insert(RoleTagGuids, "tagGuids");
    roles.insert(RoleDeleted, "deleted");
    roles.insert(RoleLoading, "loading");
    roles.insert(RoleSynced, "synced");
    roles.insert(RoleSyncError, "syncError");
    roles.insert(RoleConflicting, "conflicting");
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
    QString newGuid = QUuid::createUuid().toString();
    newGuid.remove("{").remove("}");
    qCDebug(dcNotesStore) << "Creating notebook:" << newGuid;
    Notebook *notebook = new Notebook(newGuid, 1, this);
    notebook->setName(name);
    if (m_notebooks.isEmpty()) {
        notebook->setIsDefaultNotebook(true);
    }

    m_notebooks.append(notebook);
    m_notebooksHash.insert(notebook->guid(), notebook);
    emit notebookAdded(notebook->guid());

    syncToCacheFile(notebook);

    if (EvernoteConnection::instance()->isConnected()) {
        qCDebug(dcSync) << "Creating notebook on server:" << notebook->guid();
        notebook->setLoading(true);
        CreateNotebookJob *job = new CreateNotebookJob(notebook);
        connect(job, &CreateNotebookJob::jobDone, this, &NotesStore::createNotebookJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::createNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Notebook &result)
{
    Notebook *notebook = m_notebooksHash.value(tmpGuid);
    if (!notebook) {
        qCWarning(dcSync) << "Cannot find temporary notebook after create finished";
        return;
    }

    notebook->setLoading(false);

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Error creating notebook:" << errorMessage;
        notebook->setSyncError(true);
        return;
    }
    QString guid = QString::fromStdString(result.guid);

    qCDebug(dcSync)  << "Notebook created on server. Old guid:" << tmpGuid << "New guid:" << guid;
    qCDebug(dcNotesStore) << "Changing notebook guid. Old guid:" << tmpGuid << "New guid:" << guid;

    m_notebooksHash.insert(guid, notebook);
    notebook->setGuid(QString::fromStdString(result.guid));
    emit notebookGuidChanged(tmpGuid, notebook->guid());
    m_notebooksHash.remove(tmpGuid);

    notebook->setUpdateSequenceNumber(result.updateSequenceNum);
    notebook->setLastSyncedSequenceNumber(result.updateSequenceNum);
    notebook->setName(QString::fromStdString(result.name));
    emit notebookChanged(notebook->guid());

    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notebooks");
    cacheFile.remove(tmpGuid);
    cacheFile.endGroup();

    syncToCacheFile(notebook);

    foreach (const QString &noteGuid, notebook->m_notesList) {
        saveNote(noteGuid);
    }
}

void NotesStore::saveNotebook(const QString &guid)
{
    Notebook *notebook = m_notebooksHash.value(guid);
    if (!notebook) {
        qCWarning(dcNotesStore) << "Can't save notebook. Guid not found:" << guid;
        return;
    }

    notebook->setUpdateSequenceNumber(notebook->updateSequenceNumber()+1);
    syncToCacheFile(notebook);

    if (EvernoteConnection::instance()->isConnected()) {
        SaveNotebookJob *job = new SaveNotebookJob(notebook, this);
        connect(job, &SaveNotebookJob::jobDone, this, &NotesStore::saveNotebookJobDone);
        EvernoteConnection::instance()->enqueue(job);
        notebook->setLoading(true);
    }
    emit notebookChanged(notebook->guid());
}

void NotesStore::setDefaultNotebook(const QString &guid)
{
    Notebook *notebook = m_notebooksHash.value(guid);
    if (!notebook) {
        qCWarning(dcNotesStore) << "Notebook guid not found:" << guid;
        return;
    }

    qCDebug(dcNotesStore) << "Setting default notebook:" << guid;
    foreach (Notebook *tmp, m_notebooks) {
        if (tmp->isDefaultNotebook()) {
            tmp->setIsDefaultNotebook(false);
            saveNotebook(tmp->guid());
            break;
        }
    }
    notebook->setIsDefaultNotebook(true);
    saveNotebook(guid);
    emit defaultNotebookChanged(guid);
}

void NotesStore::saveTag(const QString &guid)
{
    Tag *tag = m_tagsHash.value(guid);
    if (!tag) {
        qCWarning(dcNotesStore) << "Can't save tag. Guid not found:" << guid;
        return;
    }

    tag->setUpdateSequenceNumber(tag->updateSequenceNumber()+1);
    syncToCacheFile(tag);

    if (EvernoteConnection::instance()->isConnected()) {
        tag->setLoading(true);
        emit tagChanged(tag->guid());
        SaveTagJob *job = new SaveTagJob(tag);
        connect(job, &SaveTagJob::jobDone, this, &NotesStore::saveTagJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::expungeNotebook(const QString &guid)
{
    if (m_username != "@local") {
        qCWarning(dcNotesStore) << "Account managed by Evernote. Cannot delete notebooks.";
        m_errorQueue.append(QString(gettext("This account is managed by Evernote. Use the Evernote website to delete notebooks.")));
        emit errorChanged();
        return;
    }

    Notebook* notebook = m_notebooksHash.value(guid);
    if (!notebook) {
        qCWarning(dcNotesStore) << "Cannot delete notebook. Notebook not found for guid:" << guid;
        return;
    }

    if (notebook->isDefaultNotebook()) {
        qCWarning(dcNotesStore) << "Cannot delete the default notebook.";
        m_errorQueue.append(QString(gettext("Cannot delete the default notebook. Set another notebook to be the default first.")));
        emit errorChanged();
        return;
    }

    if (notebook->noteCount() > 0) {
        QString defaultNotebook;
        foreach (const Notebook *notebook, m_notebooks) {
            if (notebook->isDefaultNotebook()) {
                defaultNotebook = notebook->guid();
                break;
            }
        }
        if (defaultNotebook.isEmpty()) {
            qCWarning(dcNotesStore) << "No default notebook set. Can't delete notebooks.";
            return;
        }

        while (notebook->noteCount() > 0) {
            QString noteGuid = notebook->noteAt(0);
            Note *note = m_notesHash.value(noteGuid);
            if (!note) {
                qCWarning(dcNotesStore) << "Notebook holds a noteGuid which cannot be found in notes store";
                Q_ASSERT(false);
                continue;
            }
            qCDebug(dcNotesStore) << "Moving note" << noteGuid << "to default Notebook";
            note->setNotebookGuid(defaultNotebook);
            saveNote(note->guid());
            emit noteChanged(note->guid(), defaultNotebook);
            syncToCacheFile(note);
        }
    }

    m_notebooks.removeAll(notebook);
    m_notebooksHash.remove(notebook->guid());
    emit notebookRemoved(notebook->guid());

    QSettings settings(m_cacheFile, QSettings::IniFormat);
    settings.beginGroup("notebooks");
    settings.remove(notebook->guid());
    settings.endGroup();

    notebook->deleteInfoFile();
    notebook->deleteLater();
}

QList<Tag *> NotesStore::tags() const
{
    return m_tags;
}

Tag *NotesStore::tag(const QString &guid)
{
    return m_tagsHash.value(guid);
}

Tag* NotesStore::createTag(const QString &name)
{
    QString newGuid = QUuid::createUuid().toString();
    newGuid.remove("{").remove("}");
    Tag *tag = new Tag(newGuid, 1, this);
    tag->setName(name);
    m_tags.append(tag);
    m_tagsHash.insert(tag->guid(), tag);
    emit tagAdded(tag->guid());

    syncToCacheFile(tag);

    if (EvernoteConnection::instance()->isConnected()) {
        CreateTagJob *job = new CreateTagJob(tag);
        connect(job, &CreateTagJob::jobDone, this, &NotesStore::createTagJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
    return tag;
}

void NotesStore::createTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Tag &result)
{
    Tag *tag = m_tagsHash.value(tmpGuid);
    if (!tag) {
        qCWarning(dcSync) << "Create Tag job done but tag can't be found any more";
        return;
    }

    tag->setLoading(false);
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Error creating tag on server:" << errorMessage;
        tag->setSyncError(true);
        emit tagChanged(tag->guid());
        return;
    }

    QString guid = QString::fromStdString(result.guid);
    m_tagsHash.insert(guid, tag);
    tag->setGuid(QString::fromStdString(result.guid));
    emit tagGuidChanged(tmpGuid, guid);
    m_tagsHash.remove(tmpGuid);

    tag->setUpdateSequenceNumber(result.updateSequenceNum);
    tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
    emit tagChanged(tag->guid());

    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("tags");
    cacheFile.remove(tmpGuid);
    cacheFile.endGroup();

    syncToCacheFile(tag);

    foreach (const QString &noteGuid, tag->m_notesList) {
        saveNote(noteGuid);
    }
}

void NotesStore::saveTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Tag &result)
{
    Tag *tag = m_tagsHash.value(QString::fromStdString(result.guid));
    if (!tag) {
        qCWarning(dcSync) << "Save tag job finished, but tag can't be found any more";
        return;
    }
    tag->setLoading(false);
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Error updating tag on server" << errorMessage;
        tag->setSyncError(true);
        emit tagChanged(tag->guid());
        return;
    }

    tag->setName(QString::fromStdString(result.name));
    tag->setUpdateSequenceNumber(result.updateSequenceNum);
    tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
    emit tagChanged(tag->guid());
    syncToCacheFile(tag);
}

void NotesStore::tagNote(const QString &noteGuid, const QString &tagGuid)
{
    Note *note = m_notesHash.value(noteGuid);
    if (!note) {
        qCWarning(dcNotesStore) << "No such note" << noteGuid;
        return;
    }

    Tag *tag = m_tagsHash.value(tagGuid);
    if (!tag) {
        qCWarning(dcNotesStore) << "No such tag" << tagGuid;
        return;
    }

    if (note->tagGuids().contains(tagGuid)) {
        qCWarning(dcNotesStore) << "Note" << noteGuid << "already tagged with tag" << tagGuid;
        return;
    }

    note->setTagGuids(note->tagGuids() << tagGuid);
    saveNote(noteGuid);
}

void NotesStore::untagNote(const QString &noteGuid, const QString &tagGuid)
{
    Note *note = m_notesHash.value(noteGuid);
    if (!note) {
        qCWarning(dcNotesStore) << "No such note" << noteGuid;
        return;
    }

    Tag *tag = m_tagsHash.value(tagGuid);
    if (!tag) {
        qCWarning(dcNotesStore) << "No such tag" << tagGuid;
        return;
    }

    if (!note->tagGuids().contains(tagGuid)) {
        qCWarning(dcNotesStore) << "Note" << noteGuid << "is not tagged with tag" << tagGuid;
        return;
    }

    QStringList newTagGuids = note->tagGuids();
    newTagGuids.removeAll(tagGuid);
    note->setTagGuids(newTagGuids);
    saveNote(noteGuid);
}

void NotesStore::refreshNotes(const QString &filterNotebookGuid, int startIndex)
{
    if (m_loading && startIndex == 0) {
        qCWarning(dcSync) << "Still busy with refreshing...";
        return;
    }

    if (EvernoteConnection::instance()->isConnected()) {
        m_loading = true;
        emit loadingChanged();

        if (startIndex == 0) {
            m_unhandledNotes = m_notesHash.keys();
        }

        FetchNotesJob *job = new FetchNotesJob(filterNotebookGuid, QString(), startIndex);
        connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results, const QString &filterNotebookGuid)
{
    switch (errorCode) {
    case EvernoteConnection::ErrorCodeNoError:
        // All is well...
        break;
    case EvernoteConnection::ErrorCodeUserException:
        qCWarning(dcSync) << "FetchNotesJobDone: EDAMUserException:" << errorMessage;
        m_loading = false;
        emit loadingChanged();
        return; // silently discarding...
    case EvernoteConnection::ErrorCodeConnectionLost:
        qCWarning(dcSync) << "FetchNotesJobDone: Connection with evernote lost:" << errorMessage;
        m_loading = false;
        emit loadingChanged();
        return; // silently discarding...
    case EvernoteConnection::ErrorCodeNotFoundExcpetion:
        qCWarning(dcSync) << "FetchNotesJobDone: Item not found on server:" << errorMessage;
        m_loading = false;
        emit loadingChanged();
        return; // silently discarding...
    default:
        qCWarning(dcSync) << "FetchNotesJobDone: Failed to fetch notes list:" << errorMessage << errorCode;
        m_loading = false;
        emit loadingChanged();
        return;
    }

    for (unsigned int i = 0; i < results.notes.size(); ++i) {
        evernote::edam::NoteMetadata result = results.notes.at(i);
        Note *note = m_notesHash.value(QString::fromStdString(result.guid));
        m_unhandledNotes.removeAll(QString::fromStdString(result.guid));
        QVector<int> changedRoles;
        bool newNote = note == 0;
        if (newNote) {
            qCDebug(dcSync) << "Found new note on server. Creating local copy:" << QString::fromStdString(result.guid);
            note = new Note(QString::fromStdString(result.guid), 0, this);
            connect(note, &Note::reminderChanged, this, &NotesStore::emitDataChanged);
            connect(note, &Note::reminderDoneChanged, this, &NotesStore::emitDataChanged);

            updateFromEDAM(result, note);
            beginInsertRows(QModelIndex(), m_notes.count(), m_notes.count());
            m_notesHash.insert(note->guid(), note);
            m_notes.append(note);
            endInsertRows();
            emit noteAdded(note->guid(), note->notebookGuid());
            emit countChanged();
            syncToCacheFile(note);

        } else if (note->synced()) {
            // Local note did not change. Check if we need to refresh from server.
            if (note->updateSequenceNumber() < result.updateSequenceNum) {
                qCDebug(dcSync) << "refreshing note from network. suequence number changed: " << note->updateSequenceNumber() << "->" << result.updateSequenceNum;
                changedRoles = updateFromEDAM(result, note);
                refreshNoteContent(note->guid(), FetchNoteJob::LoadContent, EvernoteJob::JobPriorityMedium);
                syncToCacheFile(note);
            }
        } else {
            // Local note changed. See if we can push our changes.
            if (note->lastSyncedSequenceNumber() == result.updateSequenceNum) {
                qCDebug(dcSync) << "Local note" << note->guid() << "has changed while server note did not. Pushing changes.";

                // Make sure we have everything loaded from cache before saving to server
                if (!note->loaded() && note->isCached()) {
                    note->loadFromCacheFile();
                }

                note->setLoading(true);
                changedRoles << RoleLoading;
                SaveNoteJob *job = new SaveNoteJob(note, this);
                connect(job, &SaveNoteJob::jobDone, this, &NotesStore::saveNoteJobDone);
                EvernoteConnection::instance()->enqueue(job);
            } else {
                qCWarning(dcSync) << "CONFLICT: Note has been changed on server and locally!";
                qCWarning(dcSync) << "local note sequence:" << note->updateSequenceNumber();
                qCWarning(dcSync) << "last synced sequence:" << note->lastSyncedSequenceNumber();
                qCWarning(dcSync) << "remote sequence:" << result.updateSequenceNum;
                note->setConflicting(true);
                changedRoles << RoleConflicting;
            }
        }

        if (!results.searchedWords.empty()) {
            note->setIsSearchResult(true);
            changedRoles << RoleIsSearchResult;
        }

        if (changedRoles.count() > 0) {
            QModelIndex noteIndex = index(m_notes.indexOf(note));
            emit dataChanged(noteIndex, noteIndex, changedRoles);
            emit noteChanged(note->guid(), note->notebookGuid());
        }
    }

    if (results.startIndex + (int32_t)results.notes.size() < results.totalNotes) {
        qCDebug(dcSync) << "Not all notes fetched yet. Fetching next batch.";
        refreshNotes(filterNotebookGuid, results.startIndex + results.notes.size());
    } else {
        qCDebug(dcSync) << "Fetched all notes from Evernote. Starting merge of local changes...";
        m_organizerAdapter->startSync();
        m_loading = false;
        emit loadingChanged();


        foreach (const QString &unhandledGuid, m_unhandledNotes) {
            Note *note = m_notesHash.value(unhandledGuid);
            if (!note) {
                continue; // Note might be deleted locally by now
            }
            qCDebug(dcSync) << "Have a local note that's not available on server!" << note->guid();
            if (note->lastSyncedSequenceNumber() == 0) {
                // This note hasn't been created on the server yet. Do that now.
                bool hasUnsyncedTag = false;
                foreach (const QString &tagGuid, note->tagGuids()) {
                    Tag *tag = m_tagsHash.value(tagGuid);
                    Q_ASSERT_X(tag, "FetchNotesJob done", "note->tagGuids() contains a non existing tag.");
                    if (tag && tag->lastSyncedSequenceNumber() == 0) {
                        hasUnsyncedTag = true;
                        break;
                    }
                }
                if (hasUnsyncedTag) {
                    qCDebug(dcSync) << "Not syncing note to server yet. Have a tag that needs sync first";
                    continue;
                }
                Notebook *notebook = m_notebooksHash.value(note->notebookGuid());
                if (notebook && notebook->lastSyncedSequenceNumber() == 0) {
                    qCDebug(dcSync) << "Not syncing note to server yet. The notebook needs to be synced first";
                    continue;
                }
                qCDebug(dcSync) << "Creating note on server:" << note->guid();

                // Make sure we have everything loaded from cache before saving to server
                if (!note->loaded() && note->isCached()) {
                    note->loadFromCacheFile();
                }

                QModelIndex idx = index(m_notes.indexOf(note));
                note->setLoading(true);
                emit dataChanged(idx, idx, QVector<int>() << RoleLoading);
                CreateNoteJob *job = new CreateNoteJob(note, this);
                connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
                EvernoteConnection::instance()->enqueue(job);
            } else {
                // This note has been deleted from the server... drop it
                int idx = m_notes.indexOf(note);
                if (idx > -1) {
                    beginRemoveRows(QModelIndex(), idx, idx);
                    m_notes.removeAt(idx);
                    m_notesHash.remove(note->guid());
                    endRemoveRows();
                    emit noteRemoved(note->guid(), note->notebookGuid());
                    emit countChanged();

                    QSettings settings(m_cacheFile, QSettings::IniFormat);
                    settings.beginGroup("notes");
                    settings.remove(note->guid());
                    settings.endGroup();

                    note->deleteLater();
                }
            }
        }
        qCDebug(dcSync) << "Local changes merged.";
    }
}

void NotesStore::refreshNoteContent(const QString &guid, FetchNoteJob::LoadWhat what, EvernoteJob::JobPriority priority)
{
    Note *note = m_notesHash.value(guid);
    if (!note) {
        qCWarning(dcSync) << "RefreshNoteContent: Can't refresn note content. Note guid not found:" << guid;
        return;
    }
    if (EvernoteConnection::instance()->isConnected()) {
        qCDebug(dcNotesStore) << "Fetching note content from network for note" << guid << (what == FetchNoteJob::LoadContent ? "Content" : "Resource") << "Priority:" << priority;
        FetchNoteJob *job = new FetchNoteJob(guid, what, this);
        job->setJobPriority(priority);
        connect(job, &FetchNoteJob::resultReady, this, &NotesStore::fetchNoteJobDone);
        EvernoteConnection::instance()->enqueue(job);

        if (!note->loading()) {
            note->setLoading(true);
            int idx = m_notes.indexOf(note);
            emit dataChanged(index(idx), index(idx), QVector<int>() << RoleLoading);
        }
    }
}

void NotesStore::fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result, FetchNoteJob::LoadWhat what)
{
    FetchNoteJob *job = static_cast<FetchNoteJob*>(sender());
    Note *note = m_notesHash.value(QString::fromStdString(result.guid));
    if (!note) {
        qCWarning(dcSync) << "can't find note for this update... ignoring...";
        return;
    }

    QModelIndex noteIndex = index(m_notes.indexOf(note));
    QVector<int> roles;

    switch (errorCode) {
    case EvernoteConnection::ErrorCodeNoError:
        // All is well
        break;
    case EvernoteConnection::ErrorCodeUserException:
        qCWarning(dcSync) << "FetchNoteJobDone: EDAMUserException:" << errorMessage;
        emit dataChanged(noteIndex, noteIndex, roles);
        return; // silently discarding...
    case EvernoteConnection::ErrorCodeConnectionLost:
        qCWarning(dcSync) << "FetchNoteJobDone: Connection with evernote lost:" << errorMessage;
        emit dataChanged(noteIndex, noteIndex, roles);
        return; // silently discarding...
    case EvernoteConnection::ErrorCodeNotFoundExcpetion:
        qCWarning(dcSync) << "FetchNoteJobDone: Item not found on server:" << errorMessage;
        emit dataChanged(noteIndex, noteIndex, roles);
        return; // silently discarding...
    default:
        qCWarning(dcSync) << "FetchNoteJobDone: Failed to fetch note content:" << errorMessage << errorCode;
        note->setSyncError(true);
        roles << RoleSyncError;
        emit dataChanged(noteIndex, noteIndex, roles);
        return;
    }

    if (note->notebookGuid() != QString::fromStdString(result.notebookGuid)) {
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
        roles << RoleGuid;
    }
    if (note->title() != QString::fromStdString(result.title)) {
        note->setTitle(QString::fromStdString(result.title));
        roles << RoleTitle;
    }
    if (note->updated() != QDateTime::fromMSecsSinceEpoch(result.updated)) {
        note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));
        roles << RoleUpdated << RoleUpdatedString;
    }

    // Notes are fetched without resources by default. if we discover one or more resources where we don't have
    // data in the cache, let's refresh the note again with resource data.
    bool refreshWithResourceData = false;

    qCDebug(dcSync) << "got note content" << note->guid() << (what == FetchNoteJob::LoadContent ? "content" : "image") << result.resources.size();
    // Resources need to be set before the content because otherwise the image provider won't find them when the content is updated in the ui
    for (unsigned int i = 0; i < result.resources.size(); ++i) {

        evernote::edam::Resource resource = result.resources.at(i);

        QString hash = QByteArray::fromRawData(resource.data.bodyHash.c_str(), resource.data.bodyHash.length()).toHex();
        QString fileName = QString::fromStdString(resource.attributes.fileName);
        QString mime = QString::fromStdString(resource.mime);

        if (what == FetchNoteJob::LoadResources) {
            qCDebug(dcSync) << "Resource content fetched for note:" << note->guid() << "Filename:" << fileName << "Mimetype:" << mime << "Hash:" << hash;
            QByteArray resourceData = QByteArray(resource.data.body.data(), resource.data.size);
            note->addResource(hash, fileName, mime, resourceData);
        } else {
            qCDebug(dcSync) << "Adding resource info to note:" << note->guid() << "Filename:" << fileName << "Mimetype:" << mime << "Hash:" << hash;
            Resource *resource = note->addResource(hash, fileName, mime);

            if (!resource->isCached()) {
                qCDebug(dcSync) << "Resource not yet fetched for note:" << note->guid() << "Filename:" << fileName << "Mimetype:" << mime << "Hash:" << hash;
                refreshWithResourceData = true;
            }
        }
        roles << RoleHtmlContent << RoleEnmlContent << RoleResourceUrls;
    }

    if (what == FetchNoteJob::LoadContent) {
        note->setEnmlContent(QString::fromStdString(result.content));
        note->setUpdateSequenceNumber(result.updateSequenceNum);
        roles << RoleHtmlContent << RoleEnmlContent << RoleTagline << RolePlaintextContent;
    }
    if (note->reminderOrder() != result.attributes.reminderOrder) {
        note->setReminderOrder(result.attributes.reminderOrder);
        roles << RoleReminder;
    }
    QDateTime reminderTime;
    if (result.attributes.reminderTime > 0) {
        reminderTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderTime);
    }
    if (note->reminderTime() != reminderTime) {
        note->setReminderTime(reminderTime);
        roles << RoleReminderTime << RoleReminderTimeString;
    }
    QDateTime reminderDoneTime;
    if (result.attributes.reminderDoneTime > 0) {
        reminderDoneTime = QDateTime::fromMSecsSinceEpoch(result.attributes.reminderDoneTime);
    }
    if (note->reminderDoneTime() != reminderDoneTime) {
        note->setReminderDoneTime(reminderDoneTime);
        roles << RoleReminderDone << RoleReminderDoneTime;
    }

    note->setLoading(false);
    roles << RoleLoading;

    emit noteChanged(note->guid(), note->notebookGuid());
    emit dataChanged(noteIndex, noteIndex, roles);

    if (refreshWithResourceData) {
        qCDebug(dcSync) << "Fetching Note resources:" << note->guid();
        EvernoteJob::JobPriority newPriority = job->jobPriority() == EvernoteJob::JobPriorityMedium ? EvernoteJob::JobPriorityLow : job->jobPriority();
        refreshNoteContent(note->guid(), FetchNoteJob::LoadResources, newPriority);
    }
    syncToCacheFile(note); // Syncs into the list cache
    note->syncToCacheFile(); // Syncs note's content into notes cache
}

void NotesStore::refreshNotebooks()
{
    if (!EvernoteConnection::instance()->isConnected()) {
        qCWarning(dcSync) << "Not connected. Cannot fetch notebooks from server.";
        return;
    }

    m_notebooksLoading = true;
    emit notebooksLoadingChanged();
    FetchNotebooksJob *job = new FetchNotebooksJob();
    connect(job, &FetchNotebooksJob::jobDone, this, &NotesStore::fetchNotebooksJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results)
{
    m_notebooksLoading = false;
    emit notebooksLoadingChanged();

    switch (errorCode) {
    case EvernoteConnection::ErrorCodeNoError:
        // All is well...
        break;
    case EvernoteConnection::ErrorCodeUserException:
        qCWarning(dcSync) << "FetchNotebooksJobDone: EDAMUserException:" << errorMessage;
        // silently discarding...
        return;
    case EvernoteConnection::ErrorCodeConnectionLost:
        qCWarning(dcSync) << "FetchNotebooksJobDone: Connection lost:" << errorMessage;
        return; // silently discarding
    default:
        qCWarning(dcSync) << "FetchNotebooksJobDone: Failed to fetch notes list:" << errorMessage << errorCode;
        return; // silently discarding
    }

    QList<Notebook*> unhandledNotebooks = m_notebooks;

    qCDebug(dcSync) << "Received" << results.size() << "notebooks from Evernote.";
    for (unsigned int i = 0; i < results.size(); ++i) {
        evernote::edam::Notebook result = results.at(i);
        Notebook *notebook = m_notebooksHash.value(QString::fromStdString(result.guid));
        unhandledNotebooks.removeAll(notebook);
        bool newNotebook = notebook == 0;
        if (newNotebook) {
            qCDebug(dcSync) << "Found new notebook on Evernote:" << QString::fromStdString(result.guid);
            notebook = new Notebook(QString::fromStdString(result.guid), 0, this);
            updateFromEDAM(result, notebook);
            m_notebooksHash.insert(notebook->guid(), notebook);
            m_notebooks.append(notebook);
            emit notebookAdded(notebook->guid());
            syncToCacheFile(notebook);
        } else if (notebook->synced()) {
            if (notebook->updateSequenceNumber() < result.updateSequenceNum) {
                qCDebug(dcSync) << "Notebook on Evernote is newer than local copy. Updating:" << notebook->guid();
                updateFromEDAM(result, notebook);
                emit notebookChanged(notebook->guid());
                syncToCacheFile(notebook);
            }
        } else {
            // Local notebook changed. See if we can push our changes
            if (result.updateSequenceNum == notebook->lastSyncedSequenceNumber()) {
                qCDebug(dcNotesStore) << "Local Notebook changed. Uploading changes to Evernote:" << notebook->guid();
                SaveNotebookJob *job = new SaveNotebookJob(notebook);
                connect(job, &SaveNotebookJob::jobDone, this, &NotesStore::saveNotebookJobDone);
                EvernoteConnection::instance()->enqueue(job);
                notebook->setLoading(true);
                emit notebookChanged(notebook->guid());
            } else {
                qCWarning(dcNotesStore) << "Sync conflict in notebook:" << notebook->name();
                qCWarning(dcNotesStore) << "Resolving of sync conflicts is not implemented yet.";
                notebook->setSyncError(true);
                emit notebookChanged(notebook->guid());
            }
        }
    }

    qCDebug(dcSync) << "Remote notebooks merged into storage. Merging local changes to server.";

    foreach (Notebook *notebook, unhandledNotebooks) {
        if (notebook->lastSyncedSequenceNumber() == 0) {
            qCDebug(dcSync) << "Have a local notebook that doesn't exist on Evernote. Creating on server:" << notebook->guid();
            notebook->setLoading(true);
            CreateNotebookJob *job = new CreateNotebookJob(notebook);
            connect(job, &CreateNotebookJob::jobDone, this, &NotesStore::createNotebookJobDone);
            EvernoteConnection::instance()->enqueue(job);
            emit notebookChanged(notebook->guid());
        } else {
            qCDebug(dcSync) << "Notebook has been deleted on the server. Deleting local copy:" << notebook->guid();
            m_notebooks.removeAll(notebook);
            m_notebooksHash.remove(notebook->guid());
            emit notebookRemoved(notebook->guid());

            QSettings settings(m_cacheFile, QSettings::IniFormat);
            settings.beginGroup("notebooks");
            settings.remove(notebook->guid());
            settings.endGroup();

            notebook->deleteInfoFile();
            notebook->deleteLater();
        }
    }

    qCDebug(dcSync) << "Notebooks merged.";
}

void NotesStore::refreshTags()
{
    if (!EvernoteConnection::instance()->isConnected()) {
        qCWarning(dcSync) << "Not connected. Cannot fetch tags from server.";
        return;
    }
    m_tagsLoading = true;
    emit tagsLoadingChanged();
    FetchTagsJob *job = new FetchTagsJob();
    connect(job, &FetchTagsJob::jobDone, this, &NotesStore::fetchTagsJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::clearError()
{
    if (m_errorQueue.count() > 0) {
        m_errorQueue.takeFirst();
        emit errorChanged();
    }
}

void NotesStore::fetchTagsJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Tag> &results)
{
    m_tagsLoading = false;
    emit tagsLoadingChanged();

    switch (errorCode) {
    case EvernoteConnection::ErrorCodeNoError:
        // All is well...
        break;
    case EvernoteConnection::ErrorCodeUserException:
        qCWarning(dcSync) << "FetchTagsJobDone: EDAMUserException:" << errorMessage;
        // silently discarding...
        return;
    case EvernoteConnection::ErrorCodeConnectionLost:
        qCWarning(dcSync) << "FetchTagsJobDone: Connection lost:" << errorMessage;
        return; // silently discarding
    default:
        qCWarning(dcSync) << "FetchTagsJobDone: Failed to fetch notes list:" << errorMessage << errorCode;
        return; // silently discarding
    }

    QHash<QString, Tag*> unhandledTags = m_tagsHash;
    for (unsigned int i = 0; i < results.size(); ++i) {
        evernote::edam::Tag result = results.at(i);
        unhandledTags.remove(QString::fromStdString(result.guid));
        Tag *tag = m_tagsHash.value(QString::fromStdString(result.guid));
        bool newTag = tag == 0;
        if (newTag) {
            tag = new Tag(QString::fromStdString(result.guid), result.updateSequenceNum, this);
            tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
            qCDebug(dcSync) << "got new tag with seq:" << result.updateSequenceNum << tag->synced() << tag->updateSequenceNumber() << tag->lastSyncedSequenceNumber();
            tag->setName(QString::fromStdString(result.name));
            m_tagsHash.insert(tag->guid(), tag);
            m_tags.append(tag);
            emit tagAdded(tag->guid());
            syncToCacheFile(tag);
        } else if (tag->synced()) {
            if (tag->updateSequenceNumber() < result.updateSequenceNum) {
                tag->setName(QString::fromStdString(result.name));
                tag->setUpdateSequenceNumber(result.updateSequenceNum);
                tag->setLastSyncedSequenceNumber(result.updateSequenceNum);
                emit tagChanged(tag->guid());
                syncToCacheFile(tag);
            }
        } else {
            // local tag changed. See if we can sync it to the server
            if (result.updateSequenceNum == tag->lastSyncedSequenceNumber()) {
                SaveTagJob *job = new SaveTagJob(tag);
                connect(job, &SaveTagJob::jobDone, this, &NotesStore::saveTagJobDone);
                EvernoteConnection::instance()->enqueue(job);
                tag->setLoading(true);
                emit tagChanged(tag->guid());
            } else {
                qCWarning(dcSync) << "CONFLICT in tag" << tag->name();
                tag->setSyncError(true);
                emit tagChanged(tag->guid());
            }
        }


    }

    foreach (Tag *tag, unhandledTags) {
        if (tag->lastSyncedSequenceNumber() == 0) {
            tag->setLoading(true);
            CreateTagJob *job = new CreateTagJob(tag);
            connect(job, &CreateTagJob::jobDone, this, &NotesStore::createTagJobDone);
            EvernoteConnection::instance()->enqueue(job);
            emit tagChanged(tag->guid());
        } else {
            m_tags.removeAll(tag);
            m_tagsHash.remove(tag->guid());
            emit tagRemoved(tag->guid());

            tag->deleteInfoFile();
            tag->deleteLater();
        }
    }
}

Note* NotesStore::createNote(const QString &title, const QString &notebookGuid, const QString &richTextContent)
{
    EnmlDocument enmlDoc;
    enmlDoc.setRichText(richTextContent);
    return createNote(title, notebookGuid, enmlDoc);
}

Note* NotesStore::createNote(const QString &title, const QString &notebookGuid, const EnmlDocument &content)
{
    QString newGuid = QUuid::createUuid().toString();
    newGuid.remove("{").remove("}");
    Note *note = new Note(newGuid, 1, this);
    connect(note, &Note::reminderChanged, this, &NotesStore::emitDataChanged);
    connect(note, &Note::reminderDoneChanged, this, &NotesStore::emitDataChanged);

    note->setTitle(title);

    if (!notebookGuid.isEmpty()) {
        note->setNotebookGuid(notebookGuid);
    } else if (m_notebooks.count() > 0){
        QString generatedNotebook = m_notebooks.first()->guid();
        foreach (Notebook *notebook, m_notebooks) {
            if (notebook->isDefaultNotebook()) {
                generatedNotebook = notebook->guid();
                break;
            }
        }
        note->setNotebookGuid(generatedNotebook);
    }
    note->setEnmlContent(content.enml());
    note->setCreated(QDateTime::currentDateTime());
    note->setUpdated(note->created());

    beginInsertRows(QModelIndex(), m_notes.count(), m_notes.count());
    m_notesHash.insert(note->guid(), note);
    m_notes.append(note);
    endInsertRows();

    emit countChanged();
    emit noteAdded(note->guid(), note->notebookGuid());
    emit noteCreated(note->guid(), note->notebookGuid());

    syncToCacheFile(note);

    if (EvernoteConnection::instance()->isConnected()) {
        CreateNoteJob *job = new CreateNoteJob(note);
        connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
    return note;
}

void NotesStore::createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Note &result)
{
    Note *note = m_notesHash.value(tmpGuid);
    if (!note) {
        qCWarning(dcSync) << "Cannot find temporary note after create operation!";
        return;
    }
    int idx = m_notes.indexOf(note);
    QVector<int> roles;

    note->setLoading(false);
    roles << RoleLoading;

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Error creating note on server:" << tmpGuid << errorMessage;
        note->setSyncError(true);
        roles << RoleSyncError;
        emit dataChanged(index(idx), index(idx), roles);
        return;
    }

    if (note->syncError()) {
        note->setSyncError(false);
        roles << RoleSyncError;
    }

    QString guid = QString::fromStdString(result.guid);
    qCDebug(dcSync) << "Note created on server. Old guid:" << tmpGuid << "New guid:" << guid;
    m_notesHash.insert(guid, note);
    note->setGuid(guid);
    m_notesHash.remove(tmpGuid);
    emit noteGuidChanged(tmpGuid, guid);
    roles << RoleGuid;

    if (note->updateSequenceNumber() != result.updateSequenceNum) {
        note->setUpdateSequenceNumber(result.updateSequenceNum);
        note->setLastSyncedSequenceNumber(result.updateSequenceNum);
        roles << RoleSynced;
    }
    if (result.__isset.created) {
        note->setCreated(QDateTime::fromMSecsSinceEpoch(result.created));
        roles << RoleCreated;
    }
    if (result.__isset.updated) {
        note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));
        roles << RoleUpdated;
    }
    if (result.__isset.notebookGuid) {
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
        roles << RoleNotebookGuid;
    }
    if (result.__isset.title) {
        note->setTitle(QString::fromStdString(result.title));
        roles << RoleTitle;
    }
    if (result.__isset.content) {
        note->setEnmlContent(QString::fromStdString(result.content));
        roles << RoleEnmlContent << RoleRichTextContent << RoleTagline << RolePlaintextContent;
    }
    emit dataChanged(index(idx), index(idx), roles);

    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notes");
    cacheFile.remove(tmpGuid);
    cacheFile.endGroup();

    syncToCacheFile(note);
}

void NotesStore::saveNote(const QString &guid)
{
    Note *note = m_notesHash.value(guid);
    if (!note) {
        qCWarning(dcNotesStore) << "Can't save note. Guid not found:" << guid;
        return;
    }
    note->setUpdateSequenceNumber(note->updateSequenceNumber()+1);
    note->setUpdated(QDateTime::currentDateTime());
    syncToCacheFile(note);
    note->syncToCacheFile();

    if (EvernoteConnection::instance()->isConnected()) {
        note->setLoading(true);
        if (note->lastSyncedSequenceNumber() == 0) {
            // This note hasn't been created on the server yet... try that first
            CreateNoteJob *job = new CreateNoteJob(note, this);
            connect(job, &CreateNoteJob::jobDone, this, &NotesStore::createNoteJobDone);
            EvernoteConnection::instance()->enqueue(job);
        } else {
            SaveNoteJob *job = new SaveNoteJob(note, this);
            connect(job, &SaveNoteJob::jobDone, this, &NotesStore::saveNoteJobDone);
            EvernoteConnection::instance()->enqueue(job);
        }
    }

    int idx = m_notes.indexOf(note);
    emit dataChanged(index(idx), index(idx));
    emit noteChanged(guid, note->notebookGuid());

    m_organizerAdapter->startSync();
}

void NotesStore::saveNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result)
{
    qCDebug(dcSync) << "Note saved to server:" << QString::fromStdString(result.guid);
    Note *note = m_notesHash.value(QString::fromStdString(result.guid));
    if (!note) {
        qCWarning(dcSync) << "Got a save note job result, but note has disappeared locally.";
        return;
    }

    int idx = m_notes.indexOf(note);
    note->setLoading(false);

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Error saving note:" << errorMessage;
        note->setSyncError(true);
        emit dataChanged(index(idx), index(idx), QVector<int>() << RoleLoading << RoleSyncError);
        return;
    }
    note->setSyncError(false);

    note->setUpdateSequenceNumber(result.updateSequenceNum);
    note->setLastSyncedSequenceNumber(result.updateSequenceNum);
    note->setTitle(QString::fromStdString(result.title));
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));

    syncToCacheFile(note);

    QModelIndex noteIndex = index(m_notes.indexOf(note));
    emit dataChanged(noteIndex, noteIndex);
    emit noteChanged(note->guid(), note->notebookGuid());
}

void NotesStore::saveNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Notebook &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Error saving notebook to server" << errorMessage;
        return;
    }

    Notebook *notebook = m_notebooksHash.value(QString::fromStdString(result.guid));
    if (!notebook) {
        qCWarning(dcSync) << "Save notebook job done but notebook can't be found any more!";
        return;
    }
    qCDebug(dcSync) << "Notebooks saved to server:" << notebook->guid();
    updateFromEDAM(result, notebook);
    notebook->setLoading(false);
    emit notebookChanged(notebook->guid());
    syncToCacheFile(notebook);
}

void NotesStore::deleteNote(const QString &guid)
{
    Note *note = m_notesHash.value(guid);
    if (!note) {
        qCWarning(dcNotesStore) << "Note not found. Can't delete";
        return;
    }

    int idx = m_notes.indexOf(note);

    if (note->lastSyncedSequenceNumber() == 0) {
        emit noteRemoved(note->guid(), note->notebookGuid());
        beginRemoveRows(QModelIndex(), idx, idx);
        m_notes.takeAt(idx);
        m_notesHash.take(guid);
        endRemoveRows();
        emit countChanged();
        deleteFromCacheFile(note);
        note->deleteLater();
    } else {

        qCDebug(dcNotesStore) << "Setting note to deleted:" << note->guid();
        note->setDeleted(true);
        note->setUpdateSequenceNumber(note->updateSequenceNumber()+1);
        emit dataChanged(index(idx), index(idx), QVector<int>() << RoleDeleted);

        syncToCacheFile(note);
        if (EvernoteConnection::instance()->isConnected()) {
            DeleteNoteJob *job = new DeleteNoteJob(guid, this);
            connect(job, &DeleteNoteJob::jobDone, this, &NotesStore::deleteNoteJobDone);
            EvernoteConnection::instance()->enqueue(job);
        }
    }

    if (note->reminder() && !note->reminderDone()) {
        m_organizerAdapter->startSync();
    }
}

void NotesStore::findNotes(const QString &searchWords)
{
    if (EvernoteConnection::instance()->isConnected()) {
        clearSearchResults();
        FetchNotesJob *job = new FetchNotesJob(QString(), searchWords + "*");
        connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
        EvernoteConnection::instance()->enqueue(job);
    } else {
        foreach (Note *note, m_notes) {
            bool matches = note->title().contains(searchWords, Qt::CaseInsensitive);
            matches |= note->plaintextContent().contains(searchWords, Qt::CaseInsensitive);
            note->setIsSearchResult(matches);
        }
        emit dataChanged(index(0), index(m_notes.count()-1), QVector<int>() << RoleIsSearchResult);
    }
}

void NotesStore::clearSearchResults()
{
    foreach (Note *note, m_notes) {
        note->setIsSearchResult(false);
    }
    emit dataChanged(index(0), index(m_notes.count()-1), QVector<int>() << RoleIsSearchResult);
}

void NotesStore::deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Cannot delete note from server:" << errorMessage;
        return;
    }
    Note *note = m_notesHash.value(guid);
    int noteIndex = m_notes.indexOf(note);

    emit noteRemoved(guid, note->notebookGuid());

    beginRemoveRows(QModelIndex(), noteIndex, noteIndex);
    m_notes.takeAt(noteIndex);
    m_notesHash.take(guid);
    endRemoveRows();
    emit countChanged();
    deleteFromCacheFile(note);
    note->deleteLater();
}

void NotesStore::expungeNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qCWarning(dcSync) << "Error expunging notebook:" << errorMessage;
        return;
    }
    emit notebookRemoved(guid);
    Notebook *notebook = m_notebooksHash.take(guid);
    m_notebooks.removeAll(notebook);
    notebook->deleteLater();
}

void NotesStore::emitDataChanged()
{
    Note *note = qobject_cast<Note*>(sender());
    if (!note) {
        return;
    }
    int idx = m_notes.indexOf(note);
    emit dataChanged(index(idx), index(idx));
}

void NotesStore::clear()
{
    beginResetModel();
    foreach (Note *note, m_notes) {
        emit noteRemoved(note->guid(), note->notebookGuid());
        note->deleteLater();
    }
    m_notes.clear();
    m_notesHash.clear();
    endResetModel();

    while (!m_notebooks.isEmpty()) {
        Notebook *notebook = m_notebooks.takeFirst();
        m_notebooksHash.remove(notebook->guid());
        emit notebookRemoved(notebook->guid());
    }

    while (!m_tags.isEmpty()) {
        Tag *tag = m_tags.takeFirst();
        m_tagsHash.remove(tag->guid());
        emit tagRemoved(tag->guid());
    }
}

void NotesStore::syncToCacheFile(Note *note)
{
    qCDebug(dcNotesStore) << "Syncing note to disk:" << note->guid();
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notes");
    cacheFile.setValue(note->guid(), note->updateSequenceNumber());
    cacheFile.endGroup();
    note->syncToInfoFile();
}

void NotesStore::deleteFromCacheFile(Note *note)
{
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notes");
    cacheFile.remove(note->guid());
    cacheFile.endGroup();
    note->deleteFromCache();
}

void NotesStore::syncToCacheFile(Notebook *notebook)
{
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("notebooks");
    cacheFile.setValue(notebook->guid(), notebook->updateSequenceNumber());
    cacheFile.endGroup();
    notebook->syncToInfoFile();
}

void NotesStore::syncToCacheFile(Tag *tag)
{
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("tags");
    cacheFile.setValue(tag->guid(), tag->updateSequenceNumber());
    cacheFile.endGroup();
    tag->syncToInfoFile();
}

void NotesStore::loadFromCacheFile()
{
    clear();
    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);

    cacheFile.beginGroup("notebooks");
    if (cacheFile.allKeys().count() > 0) {
        foreach (const QString &key, cacheFile.allKeys()) {
            Notebook *notebook = new Notebook(key, cacheFile.value(key).toUInt(), this);
            m_notebooksHash.insert(key, notebook);
            m_notebooks.append(notebook);
            emit notebookAdded(key);
        }
    }
    cacheFile.endGroup();
    qCDebug(dcNotesStore) << "Loaded" << m_notebooks.count() << "notebooks from disk.";

    cacheFile.beginGroup("tags");
    if (cacheFile.allKeys().count() > 0) {
        foreach (const QString &key, cacheFile.allKeys()) {
            Tag *tag = new Tag(key, cacheFile.value(key).toUInt(), this);
            m_tagsHash.insert(key, tag);
            m_tags.append(tag);
            emit tagAdded(key);
        }
    }
    cacheFile.endGroup();
    qCDebug(dcNotesStore) << "Loaded" << m_tags.count() << "tags from disk.";

    cacheFile.beginGroup("notes");
    if (cacheFile.allKeys().count() > 0) {
        beginInsertRows(QModelIndex(), 0, cacheFile.allKeys().count()-1);
        foreach (const QString &key, cacheFile.allKeys()) {
            if (m_notesHash.contains(key)) {
                qCWarning(dcNotesStore) << "already have note. Not reloading from cache.";
                continue;
            }
            Note *note = new Note(key, cacheFile.value(key).toUInt(), this);
            m_notesHash.insert(key, note);
            m_notes.append(note);
            emit noteAdded(note->guid(), note->notebookGuid());
        }
        endInsertRows();
    }
    cacheFile.endGroup();
    qCDebug(dcNotesStore) << "Loaded" << m_notes.count() << "notes from disk.";
}

QVector<int> NotesStore::updateFromEDAM(const evernote::edam::NoteMetadata &evNote, Note *note)
{
    QVector<int> roles;
    if (note->guid() != QString::fromStdString(evNote.guid)) {
        note->setGuid(QString::fromStdString(evNote.guid));
        roles << RoleGuid;
    }

    if (evNote.__isset.title && note->title() != QString::fromStdString(evNote.title)) {
        note->setTitle(QString::fromStdString(evNote.title));
        roles << RoleTitle;
    }
    if (evNote.__isset.created && note->created() != QDateTime::fromMSecsSinceEpoch(evNote.created)) {
        note->setCreated(QDateTime::fromMSecsSinceEpoch(evNote.created));
        roles << RoleCreated;
    }
    if (evNote.__isset.updated && note->updated() != QDateTime::fromMSecsSinceEpoch(evNote.updated)) {
        note->setUpdated(QDateTime::fromMSecsSinceEpoch(evNote.updated));
        roles << RoleUpdated;
    }
    if (evNote.__isset.updateSequenceNum && note->updateSequenceNumber() != evNote.updateSequenceNum) {
        note->setUpdateSequenceNumber(evNote.updateSequenceNum);
    }
    if (evNote.__isset.notebookGuid && note->notebookGuid() != QString::fromStdString(evNote.notebookGuid)) {
        note->setNotebookGuid(QString::fromStdString(evNote.notebookGuid));
        roles << RoleNotebookGuid;
    }
    if (evNote.__isset.tagGuids) {
        QStringList tagGuids;
        for (quint32 i = 0; i < evNote.tagGuids.size(); i++) {
            tagGuids << QString::fromStdString(evNote.tagGuids.at(i));
        }
        if (note->tagGuids() != tagGuids) {
            note->setTagGuids(tagGuids);
            roles << RoleTagGuids;
        }
    }
    if (evNote.__isset.attributes && evNote.attributes.__isset.reminderTime) {
        QDateTime reminderTime;
        if (evNote.attributes.reminderTime > 0) {
            reminderTime = QDateTime::fromMSecsSinceEpoch(evNote.attributes.reminderTime);
        }
        if (note->reminderTime() != reminderTime) {
            note->setReminderTime(reminderTime);
            roles << RoleReminderTime;
        }
    }
    if (evNote.__isset.attributes && evNote.attributes.__isset.reminderDoneTime) {
        QDateTime reminderDoneTime;
        if (evNote.attributes.reminderDoneTime > 0) {
            reminderDoneTime = QDateTime::fromMSecsSinceEpoch(evNote.attributes.reminderDoneTime);
        }
        if (note->reminderDoneTime() != reminderDoneTime) {
            note->setReminderDoneTime(reminderDoneTime);
            roles << RoleReminderDoneTime;
        }
    }
    note->setLastSyncedSequenceNumber(evNote.updateSequenceNum);
    return roles;
}

void NotesStore::updateFromEDAM(const evernote::edam::Notebook &evNotebook, Notebook *notebook)
{
    if (evNotebook.__isset.guid && QString::fromStdString(evNotebook.guid) != notebook->guid()) {
        notebook->setGuid(QString::fromStdString(evNotebook.guid));
    }
    if (evNotebook.__isset.name && QString::fromStdString(evNotebook.name) != notebook->name()) {
        notebook->setName(QString::fromStdString(evNotebook.name));
    }
    if (evNotebook.__isset.updateSequenceNum && evNotebook.updateSequenceNum != notebook->updateSequenceNumber()) {
        notebook->setUpdateSequenceNumber(evNotebook.updateSequenceNum);
    }
    if (evNotebook.__isset.serviceUpdated && QDateTime::fromMSecsSinceEpoch(evNotebook.serviceUpdated) != notebook->lastUpdated()) {
        notebook->setLastUpdated(QDateTime::fromMSecsSinceEpoch(evNotebook.serviceUpdated));
    }
    if (evNotebook.__isset.published && evNotebook.published != notebook->published()) {
        notebook->setPublished(evNotebook.published);
    }
    if (evNotebook.__isset.defaultNotebook && evNotebook.defaultNotebook != notebook->isDefaultNotebook()) {
        notebook->setIsDefaultNotebook(evNotebook.defaultNotebook);
    }
    notebook->setLastSyncedSequenceNumber(evNotebook.updateSequenceNum);
}


void NotesStore::expungeTag(const QString &guid)
{
    if (m_username != "@local") {
        qCWarning(dcNotesStore) << "This account is managed by Evernote. Cannot delete tags.";
        m_errorQueue.append(gettext("This account is managed by Evernote. Please use the Evernote website to delete tags."));
        emit errorChanged();
        return;
    }

    Tag *tag = m_tagsHash.value(guid);
    if (!tag) {
        qCWarning(dcNotesStore) << "No tag with guid" << guid;
        return;
    }

    while (tag->noteCount() > 0) {
        QString noteGuid = tag->noteAt(0);
        Note *note = m_notesHash.value(noteGuid);
        if (!note) {
            qCWarning(dcNotesStore) << "Tag holds note" << noteGuid << "which hasn't been found in Notes Store";
            continue;
        }
        untagNote(noteGuid, guid);
    }

    emit tagRemoved(guid);
    m_tagsHash.remove(guid);
    m_tags.removeAll(tag);

    QSettings cacheFile(m_cacheFile, QSettings::IniFormat);
    cacheFile.beginGroup("tags");
    cacheFile.remove(guid);
    cacheFile.endGroup();
    tag->syncToInfoFile();

    tag->deleteInfoFile();
    tag->deleteLater();
}
