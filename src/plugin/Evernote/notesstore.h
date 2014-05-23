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

class Notebook;
class Note;

using namespace apache::thrift::transport;

class NotesStore : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(bool notebooksLoading READ notebooksLoading NOTIFY notebooksLoadingChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)
    Q_PROPERTY(QString notebooksError READ notebooksError NOTIFY notebooksErrorChanged)

public:
    enum Role {
        RoleGuid,
        RoleNotebookGuid,
        RoleCreated,
        RoleCreatedString,
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
        RoleResourceUrls,
        RoleReminderSorting
    };

    ~NotesStore();
    static NotesStore *instance();

    bool loading() const;
    bool notebooksLoading() const;

    QString error() const;
    QString notebooksError() const;

    // reimplemented from QAbstractListModel
    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const;

    QList<Note*> notes() const;

    Q_INVOKABLE Note* note(const QString &guid);
    Q_INVOKABLE void createNote(const QString &title, const QString &notebookGuid = QString(), const QString &richTextContent = QString());
    void createNote(const QString &title, const QString &notebookGuid, const EnmlDocument &content);
    Q_INVOKABLE void saveNote(const QString &guid);
    Q_INVOKABLE void deleteNote(const QString &guid);
    Q_INVOKABLE void findNotes(const QString &searchWords);
    Q_INVOKABLE void clearSearchResults();

    QList<Notebook*> notebooks() const;
    Q_INVOKABLE Notebook* notebook(const QString &guid);
    Q_INVOKABLE void createNotebook(const QString &name);
    Q_INVOKABLE void expungeNotebook(const QString &guid);

public slots:
    void refreshNotes(const QString &filterNotebookGuid = QString());
    void refreshNoteContent(const QString &guid, bool withResourceContent = false);
    void refreshNotebooks();

signals:
    void tokenChanged();
    void loadingChanged();
    void notebooksLoadingChanged();
    void errorChanged();
    void notebooksErrorChanged();

    void noteCreated(const QString &guid, const QString &notebookGuid);
    void noteAdded(const QString &guid, const QString &notebookGuid);
    void noteChanged(const QString &guid, const QString &notebookGuid);
    void noteRemoved(const QString &guid, const QString &notebookGuid);

    void notebookAdded(const QString &guid);
    void notebookChanged(const QString &guid);
    void notebookRemoved(const QString &guid);

private slots:
    void fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results);
    void fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results);
    void fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result, bool withResourceContent);
    void createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void saveNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);
    void createNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Notebook &result);
    void expungeNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);

    void emitDataChanged();
private:
    explicit NotesStore(QObject *parent = 0);
    static NotesStore *s_instance;

    bool m_loading;
    bool m_notebooksLoading;

    QString m_error;
    QString m_notebooksError;

    QList<Note*> m_notes;
    QList<Notebook*> m_notebooks;

    // Keep hashes for faster lookups as we always identify notes via guid
    QHash<QString, Note*> m_notesHash;
    QHash<QString, Notebook*> m_notebooksHash;
};

#endif // NOTESSTORE_H
