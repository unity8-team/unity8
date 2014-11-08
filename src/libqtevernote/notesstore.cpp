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

#include <QImage>
#include <QDebug>
#include <QUuid>

NotesStore* NotesStore::s_instance = 0;

NotesStore::NotesStore(QObject *parent) :
    QAbstractListModel(parent),
    m_loading(false),
    m_notebooksLoading(false),
    m_tagsLoading(false)
{
    connect(EvernoteConnection::instance(), &EvernoteConnection::isConnectedChanged, this, &NotesStore::refreshNotebooks);
    connect(EvernoteConnection::instance(), SIGNAL(isConnectedChanged()), this, SLOT(refreshNotes()));
    connect(EvernoteConnection::instance(), &EvernoteConnection::isConnectedChanged, this, &NotesStore::refreshTags);
    connect(EvernoteConnection::instance(), &EvernoteConnection::tokenChanged, this, &NotesStore::clear);

    qRegisterMetaType<evernote::edam::NotesMetadataList>("evernote::edam::NotesMetadataList");
    qRegisterMetaType<evernote::edam::Note>("evernote::edam::Note");
    qRegisterMetaType<std::vector<evernote::edam::Notebook> >("std::vector<evernote::edam::Notebook>");
    qRegisterMetaType<evernote::edam::Notebook>("evernote::edam::Notebook");
    qRegisterMetaType<std::vector<evernote::edam::Tag> >("std::vector<evernote::edam::Tag>");
    qRegisterMetaType<evernote::edam::Tag>("evernote::edam::Tag");

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

bool NotesStore::tagsLoading() const
{
    return m_tagsLoading;
}

QString NotesStore::error() const
{
    return m_error;
}

QString NotesStore::notebooksError() const
{
    return m_notebooksError;
}

QString NotesStore::tagsError() const
{
    return m_tagsError;
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

void NotesStore::saveNotebook(const QString &guid)
{
    Notebook *notebook = m_notebooksHash.value(guid);
    if (!notebook) {
        qWarning() << "Can't save notebook. Guid not found:" << guid;
        return;
    }
    SaveNotebookJob *job = new SaveNotebookJob(notebook, this);
    connect(job, &SaveNotebookJob::jobDone, this, &NotesStore::saveNotebookJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::saveTag(const QString &guid)
{
    Tag *tag = m_tagsHash.value(guid);
    if (!tag) {
        qWarning() << "Can't save tag. Guid not found:" << guid;
        return;
    }
    SaveTagJob *job = new SaveTagJob(tag);
    connect(job, &SaveTagJob::jobDone, this, &NotesStore::saveTagJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::expungeNotebook(const QString &guid)
{
    ExpungeNotebookJob *job = new ExpungeNotebookJob(guid);
    connect(job, &ExpungeNotebookJob::jobDone, this, &NotesStore::expungeNotebookJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

QList<Tag *> NotesStore::tags() const
{
    return m_tags;
}

Tag *NotesStore::tag(const QString &guid)
{
    return m_tagsHash.value(guid);
}

QString NotesStore::createTag(const QString &name)
{
    QString tagGuid = QUuid::createUuid().toString();
    CreateTagJob *job = new CreateTagJob(name, tagGuid);
    connect(job, &CreateTagJob::jobDone, this, &NotesStore::createTagJobDone);
    EvernoteConnection::instance()->enqueue(job);
    return tagGuid;
}

void NotesStore::createTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Tag &result)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error creating tag:" << errorMessage;
        return;
    }
    Tag *tag = new Tag(QString::fromStdString(result.guid));
    tag->setName(QString::fromStdString(result.name));
    m_tags.append(tag);
    m_tagsHash.insert(tag->guid(), tag);
    emit tagAdded(tag->guid());
}

void NotesStore::saveTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "error updating tag" << errorMessage;

        // Lets fetch the tags from the server again to reflect the non-saved state...
        refreshTags();
        return;
    }
}

void NotesStore::tagNote(const QString &noteGuid, const QString &tagGuid)
{
    Note *note = m_notesHash.value(noteGuid);
    if (!note) {
        qWarning() << "No such note" << noteGuid;
        return;
    }

    Tag *tag = m_tagsHash.value(tagGuid);
    if (!tag) {
        qWarning() << "No such tag" << tagGuid;
        return;
    }

    if (note->tagGuids().contains(tagGuid)) {
        qWarning() << "Note" << noteGuid << "already tagged with tag" << tagGuid;
        return;
    }

    note->setTagGuids(note->tagGuids() << tagGuid);
    saveNote(noteGuid);
}

void NotesStore::untagNote(const QString &noteGuid, const QString &tagGuid)
{
    Note *note = m_notesHash.value(noteGuid);
    if (!note) {
        qWarning() << "No such note" << noteGuid;
        return;
    }

    Tag *tag = m_tagsHash.value(tagGuid);
    if (!tag) {
        qWarning() << "No such tag" << tagGuid;
        return;
    }

    if (!note->tagGuids().contains(tagGuid)) {
        qWarning() << "Note" << noteGuid << "is not tagged with tag" << tagGuid;
        return;
    }

    QStringList newTagGuids = note->tagGuids();
    newTagGuids.removeAll(tagGuid);
    note->setTagGuids(newTagGuids);
    saveNote(noteGuid);
}

void NotesStore::refreshNotes(const QString &filterNotebookGuid, int startIndex)
{
    if (EvernoteConnection::instance()->token().isEmpty()) {
        clear();
        emit countChanged();
    } else {
        m_loading = true;
        emit loadingChanged();
        FetchNotesJob *job = new FetchNotesJob(filterNotebookGuid, QString(), startIndex);
        connect(job, &FetchNotesJob::jobDone, this, &NotesStore::fetchNotesJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results, const QString &filterNotebookGuid)
{
    if (results.startIndex + (int32_t)results.notes.size() < results.totalNotes) {
        refreshNotes(filterNotebookGuid, results.startIndex + results.notes.size());
    } else {
        m_loading = false;
        emit loadingChanged();
    }

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
            connect(note, &Note::reminderChanged, this, &NotesStore::emitDataChanged);
            connect(note, &Note::reminderDoneChanged, this, &NotesStore::emitDataChanged);
        }

        note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));
        note->setTitle(QString::fromStdString(result.title));
        note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
        note->setReminderOrder(result.attributes.reminderOrder);
        QStringList tagGuids;
        for (quint32 i = 0; i < result.tagGuids.size(); i++) {
            tagGuids << QString::fromStdString(result.tagGuids.at(i));
        }
        if (note->tagGuids() != tagGuids) {
            foreach (const QString &tagGuid, tagGuids) {
                if (!note->tagGuids().contains(tagGuid)) {
                    Tag *tag = m_tagsHash.value(tagGuid);
                    if (tag) {
                        tag->m_noteCount++;
                        emit tag->noteCountChanged();
                    } else {
                        refreshTags();
                    }
                }
            }
            foreach (const QString &tagGuid, note->tagGuids()) {
                if (!tagGuids.contains(tagGuid)) {
                    Tag *tag = m_tagsHash.value(tagGuid);
                    if (tag) {
                        tag->m_noteCount--;
                        emit tag->noteCountChanged();
                    } else {
                        refreshTags();
                    }
                }
            }
        }
        note->setTagGuids(tagGuids);

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
            emit countChanged();
        } else {
            QModelIndex noteIndex = index(m_notes.indexOf(note));
            emit dataChanged(noteIndex, noteIndex);
            emit noteChanged(note->guid(), note->notebookGuid());
        }
    }
}

void NotesStore::refreshNoteContent(const QString &guid, FetchNoteJob::LoadWhat what)
{
    Note *note = m_notesHash.value(guid);
    if (note) {
        note->setLoading(true);
    }

    FetchNoteJob *job = new FetchNoteJob(guid, what, this);
    connect(job, &FetchNoteJob::resultReady, this, &NotesStore::fetchNoteJobDone);
    EvernoteConnection::instance()->enqueue(job);
}

void NotesStore::fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result, FetchNoteJob::LoadWhat what)
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
    note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));

    // Notes are fetched without resources by default. if we discover one or more resources where we don't have
    // data in the cache, just refresh the note again with resource data.
    bool refreshWithResourceData = false;

    // Resources need to be set before the content because otherwise the image provider won't find them when the content is updated in the ui
    for (unsigned int i = 0; i < result.resources.size(); ++i) {

        evernote::edam::Resource resource = result.resources.at(i);

        QString hash = QByteArray::fromRawData(resource.data.bodyHash.c_str(), resource.data.bodyHash.length()).toHex();
        QString fileName = QString::fromStdString(resource.attributes.fileName);
        QString mime = QString::fromStdString(resource.mime);

        if (what == FetchNoteJob::LoadResources) {
            QByteArray resourceData = QByteArray(resource.data.body.data(), resource.data.size);
            note->addResource(resourceData, hash, fileName, mime);
        } else if (Resource::isCached(hash)) {
            note->addResource(QByteArray(), hash, fileName, mime);
        } else {
            refreshWithResourceData = true;
        }
    }

    if (what == FetchNoteJob::LoadContent) {
        note->setEnmlContent(QString::fromStdString(result.content));
    }
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
        refreshNoteContent(note->guid(), FetchNoteJob::LoadResources);
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
        bool newNotebook = notebook == 0;
        if (newNotebook) {
            notebook = new Notebook(QString::fromStdString(result.guid), this);
        }
        notebook->setName(QString::fromStdString(result.name));
        notebook->setPublished(result.published);
        notebook->setLastUpdated(QDateTime::fromMSecsSinceEpoch(result.serviceUpdated));

        if (newNotebook) {
            m_notebooksHash.insert(notebook->guid(), notebook);
            m_notebooks.append(notebook);
            emit notebookAdded(notebook->guid());
        } else {
            emit notebookChanged(notebook->guid());
        }
    }
}

void NotesStore::refreshTags()
{
    if (EvernoteConnection::instance()->token().isEmpty()) {
        foreach (Tag *tag, m_tags) {
            emit tagRemoved(tag->guid());
            tag->deleteLater();
        }
        m_tags.clear();
    } else {
        m_tagsLoading = true;
        emit tagsLoadingChanged();
        FetchTagsJob *job = new FetchTagsJob();
        connect(job, &FetchTagsJob::jobDone, this, &NotesStore::fetchTagsJobDone);
        EvernoteConnection::instance()->enqueue(job);
    }
}

void NotesStore::fetchTagsJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Tag> &results)
{
    m_tagsLoading = false;
    emit tagsLoadingChanged();

    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "Error fetching tags:" << errorMessage;
        m_tagsError = tr("Error refreshing tags: %1").arg(errorMessage);
        emit tagsErrorChanged();
        return;
    }
    if (!m_tagsError.isEmpty()) {
        m_tagsError.clear();
        emit tagsErrorChanged();
    }

    for (unsigned int i = 0; i < results.size(); ++i) {
        evernote::edam::Tag result = results.at(i);
        Tag *tag = m_tagsHash.value(QString::fromStdString(result.guid));
        bool newTag = tag == 0;
        if (newTag) {
            tag = new Tag(QString::fromStdString(result.guid), this);
        }
        tag->setName(QString::fromStdString(result.name));

        if (newTag) {
            m_tagsHash.insert(tag->guid(), tag);
            m_tags.append(tag);
            emit tagAdded(tag->guid());
        } else {
            emit tagChanged(tag->guid());
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
    connect(note, &Note::reminderChanged, this, &NotesStore::emitDataChanged);
    connect(note, &Note::reminderDoneChanged, this, &NotesStore::emitDataChanged);
    note->setNotebookGuid(QString::fromStdString(result.notebookGuid));
    note->setTitle(QString::fromStdString(result.title));
    note->setEnmlContent(QString::fromStdString(result.content));
    note->setUpdated(created);

    beginInsertRows(QModelIndex(), m_notes.count(), m_notes.count());
    m_notesHash.insert(note->guid(), note);
    m_notes.append(note);
    endInsertRows();

    emit noteAdded(note->guid(), note->notebookGuid());
    emit noteCreated(note->guid(), note->notebookGuid());
    emit countChanged();
}

void NotesStore::saveNote(const QString &guid)
{
    Note *note = m_notesHash.value(guid);
    if (!note) {
        qWarning() << "Can't save note. Guid not found:" << guid;
        return;
    }
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
        note->setUpdated(QDateTime::fromMSecsSinceEpoch(result.updated));

        emit noteChanged(note->guid(), note->notebookGuid());

        QModelIndex noteIndex = index(m_notes.indexOf(note));
        emit dataChanged(noteIndex, noteIndex);
    }
}

void NotesStore::saveNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage)
{
    if (errorCode != EvernoteConnection::ErrorCodeNoError) {
        qWarning() << "error saving notebook" << errorMessage;

        // Lets fetch the notebook from the server again to reflect the non-saved state...
        refreshNotebooks();
        return;
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
    emit countChanged();
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
}
