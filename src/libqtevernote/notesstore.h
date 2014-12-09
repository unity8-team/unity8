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

#ifndef NOTESSTORE_H
#define NOTESSTORE_H

#include "evernoteconnection.h"
#include "utils/enmldocument.h"
#include "jobs/fetchnotejob.h"

// Thrift
#include <arpa/inet.h> // seems thrift forgot this one
#include <protocol/TBinaryProtocol.h>
#include <transport/THttpClient.h>
#include <transport/TSSLSocket.h>
#include <Thrift.h>

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QAbstractListModel>
#include <QHash>
#include <QSettings>

class Notebook;
class Note;
class Tag;
class OrganizerAdapter;

using namespace apache::thrift::transport;

class NotesStore : public QAbstractListModel
{
    Q_OBJECT
    // Setting the username will cause notes to be loaded from cache
    // If you want to load the local cache only (not associated with an Evernote account), make sure to set this to ""
    // Note that if you use EvernoteConnection to log in (by setting a token obtained from OA) this username
    // will be changed to the one used to log in. Also you won't be able to change this as long as EvernoteConnection is logged in.
    Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool notebooksLoading READ notebooksLoading NOTIFY notebooksLoadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString notebooksError READ notebooksError NOTIFY notebooksErrorChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Role {
        RoleGuid,
        RoleNotebookGuid,
        RoleCreated,
        RoleCreatedString,
        RoleUpdated,
        RoleUpdatedString,
        RoleTitle,
        RoleReminder,
        RoleReminderTime,
        RoleReminderTimeString,
        RoleReminderDone,
        RoleReminderDoneTime,
        RoleIsSearchResult,
        RoleEnmlContent,
        RoleHtmlContent,
        RoleRichTextContent,
        RolePlaintextContent,
        RoleTagline,
        RoleResourceUrls,
        RoleReminderSorting,
        RoleTagGuids,
        RoleDeleted
    };

    ~NotesStore();
    static NotesStore *instance();

    QString username() const;
    Q_SLOT void setUsername(const QString &username);

    bool loading() const;
    bool notebooksLoading() const;
    bool tagsLoading() const;

    QString error() const;
    QString notebooksError() const;
    QString tagsError() const;

    int count() const;

    // reimplemented from QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const;

    QList<Note*> notes() const;

    Q_INVOKABLE Note* note(const QString &guid);
    Q_INVOKABLE Note* createNote(const QString &title, const QString &notebookGuid = QString(), const QString &richTextContent = QString());
    Note *createNote(const QString &title, const QString &notebookGuid, const EnmlDocument &content);
    Q_INVOKABLE void saveNote(const QString &guid);
    Q_INVOKABLE void deleteNote(const QString &guid);
    Q_INVOKABLE void findNotes(const QString &searchWords);
    Q_INVOKABLE void clearSearchResults();

    QList<Notebook*> notebooks() const;
    Q_INVOKABLE Notebook* notebook(const QString &guid);
    Q_INVOKABLE void createNotebook(const QString &name);
    Q_INVOKABLE void saveNotebook(const QString &guid);
    Q_INVOKABLE void expungeNotebook(const QString &guid);

    QList<Tag*> tags() const;
    Q_INVOKABLE Tag* tag(const QString &guid);
    Q_INVOKABLE void createTag(const QString &name);
    Q_INVOKABLE void saveTag(const QString &guid);
    Q_INVOKABLE void tagNote(const QString &noteGuid, const QString &tagGuid);
    Q_INVOKABLE void untagNote(const QString &noteGuid, const QString &tagGuid);

public slots:
    void refreshNotes(const QString &filterNotebookGuid = QString(), int startIndex = 0);

    // Defaulting to High priority to provide fast feedback to the ui. Use low priority if you call this to prefetch things in the background
    void refreshNoteContent(const QString &guid, FetchNoteJob::LoadWhat what = FetchNoteJob::LoadContent, EvernoteConnection::JobPriority priority = EvernoteConnection::JobPriorityHigh);
    void refreshNotebooks();
    void refreshTags();

signals:
    void usernameChanged();
    void loadingChanged();
    void notebooksLoadingChanged();
    void tagsLoadingChanged();
    void errorChanged();
    void notebooksErrorChanged();
    void tagsErrorChanged();
    void countChanged();

    void noteCreated(const QString &guid, const QString &notebookGuid);
    void noteUpdated(const QString &guid, const QString &notebookGuid);
    void noteAdded(const QString &guid, const QString &notebookGuid);
    void noteChanged(const QString &guid, const QString &notebookGuid);
    void noteRemoved(const QString &guid, const QString &notebookGuid);

    void notebookAdded(const QString &guid);
    void notebookChanged(const QString &guid);
    void notebookRemoved(const QString &guid);

    void tagAdded(const QString &guid);
    void tagChanged(const QString &guid);
    void tagRemoved(const QString &guid);

private slots:
    void fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results, const QString &filterNotebookGuid);
    void fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results);
    void fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result, FetchNoteJob::LoadWhat what);
    void createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Note &result);
    void saveNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void saveNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);
    void deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);
    void createNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &tmpGuid, const evernote::edam::Notebook &result);
    void expungeNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);
    void fetchTagsJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Tag> &results);
    void createTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Tag &result);
    void saveTagJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage);

    void noteNotebookGuidChanged();

    void syncToCacheFile(Note *note);
    void deleteFromCacheFile(Note* note);
    void syncToCacheFile(Notebook *notebook);
    void syncToCacheFile(Tag *tag);
    void loadFromCacheFile();

    void emitDataChanged();
    void clear();

private:
    explicit NotesStore(QObject *parent = 0);
    static NotesStore *s_instance;

    QString m_username;

    bool m_loading;
    bool m_notebooksLoading;
    bool m_tagsLoading;

    QString m_error;
    QString m_notebooksError;
    QString m_tagsError;

    QList<Note*> m_notes;
    QList<Notebook*> m_notebooks;
    QList<Tag*> m_tags;

    // Keep hashes for faster lookups as we always identify things via guid
    QHash<QString, Note*> m_notesHash;
    QHash<QString, Notebook*> m_notebooksHash;
    QHash<QString, Tag*> m_tagsHash;

    // To keep track of notes that might have disappeared from the server
    QHash<QString, QPointer<Note>> m_unhandledNotes;

    OrganizerAdapter *m_organizerAdapter;

    QString m_cacheFile;
};

#endif // NOTESSTORE_H
