#ifndef NOTESSTORE_H
#define NOTESSTORE_H

#include "evernoteconnection.h"

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

public:
    enum Roles {
        RoleGuid,
        RoleNotebookGuid,
        RoleCreated,
        RoleTitle,
        RoleReminder,
        RoleReminderTime,
        RoleReminderDone,
        RoleReminderDoneTime,
        RoleIsSearchResult,
        RoleEnmlContent,
        RoleHtmlContent,
        RolePlaintextContent,
        RoleResources
    };

    ~NotesStore();
    static NotesStore *instance();

    // reimplemented from QAbstractListModel
    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role) const;
    QHash<int, QByteArray> roleNames() const;

    QList<Note*> notes() const;

    Q_INVOKABLE Note* note(const QString &guid);
    Q_INVOKABLE void createNote(const QString &title, const QString &notebookGuid, const QString &content);
    Q_INVOKABLE void saveNote(const QString &guid);
    Q_INVOKABLE void deleteNote(const QString &guid);
    Q_INVOKABLE void findNotes(const QString &searchWords);

    QList<Notebook*> notebooks() const;
    Notebook* notebook(const QString &guid);
    Q_INVOKABLE void createNotebook(const QString &name);
    Q_INVOKABLE void expungeNotebook(const QString &guid);

public slots:
    void refreshNotes(const QString &filterNotebookGuid = QString());
    void refreshNoteContent(const QString &guid);
    void refreshNotebooks();

signals:
    void tokenChanged();

    void noteAdded(const QString &guid);
    void noteChanged(const QString &guid);
    void noteRemoved(const QString &guid);

    void notebookAdded(const QString &guid);
    void notebookChanged(const QString &guid);
    void notebookRemoved(const QString &guid);

private slots:
    void fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results);
    void fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results);
    void fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void saveNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);
    void createNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Notebook &result);
    void expungeNotebookJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);

private:
    explicit NotesStore(QObject *parent = 0);
    static NotesStore *s_instance;

    QList<Note*> m_notes;
    QList<Notebook*> m_notebooks;

    // Keep hashes for faster lookups as we always identify notes via guid
    QHash<QString, Note*> m_notesHash;
    QHash<QString, Notebook*> m_notebooksHash;
};

#endif // NOTESSTORE_H
