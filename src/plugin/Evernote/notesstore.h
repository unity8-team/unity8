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

#include <QObject>
#include <QHash>

class Notebook;
class Note;

using namespace apache::thrift::transport;

class NotesStore : public QObject
{
    Q_OBJECT

public:
    Q_INVOKABLE void createNote(const QString &title, const QString &notebookGuid, const QString &content);

    static NotesStore *instance();

    ~NotesStore();

    QList<Note*> notes() const;
    Note* note(const QString &guid);
    void saveNote(const QString &guid);
    void deleteNote(const QString &guid);

    QList<Notebook*> notebooks() const;
    Notebook* notebook(const QString &guid);

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

private slots:
    void fetchNotesJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results);
    void fetchNotebooksJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results);
    void fetchNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void createNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void saveNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void deleteNoteJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &guid);

private:
    explicit NotesStore(QObject *parent = 0);
    static NotesStore *s_instance;

    QHash<QString, Notebook*> m_notebooks;
    QHash<QString, Note*> m_notes;

};

#endif // NOTESSTORE_H
