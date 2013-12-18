#ifndef NOTESSTORE_H
#define NOTESSTORE_H

// Thrift
#include <transport/THttpClient.h>

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QObject>
#include <QHash>

class EvernoteJob;

class Notebook;
class Note;

using namespace apache::thrift::transport;

class NotesStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString token READ token WRITE setToken NOTIFY tokenChanged)

    friend class EvernoteJob;

public:
    enum ErrorCode {
        ErrorCodeNoError,
        ErrorCodeUserException,
        ErrorCodeSystemException,
        ErrorCodeNotFoundExcpetion,
        ErrorCodeConnectionLost
    };

    Q_INVOKABLE void createNote(const QString &title, const QString &notebookGuid, const QString &content);

    static NotesStore *instance();
    static QString errorCodeToString(ErrorCode errorCode);

    ~NotesStore();

    QString token() const;
    void setToken(const QString &token);

    QList<Note*> notes() const;
    Note* note(const QString &guid);
    void saveNote(const QString &guid);
    void deleteNote(const QString &guid);

    QList<Notebook*> notebooks() const;
    Notebook* notebook(const QString &guid);

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
    void fetchNotesJobDone(ErrorCode errorCode, const QString &errorMessage, const evernote::edam::NotesMetadataList &results);
    void fetchNotebooksJobDone(ErrorCode errorCode, const QString &errorMessage, const std::vector<evernote::edam::Notebook> &results);
    void fetchNoteJobDone(ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void createNoteJobDone(ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void saveNoteJobDone(ErrorCode errorCode, const QString &errorMessage, const evernote::edam::Note &result);
    void deleteNoteJobDone(ErrorCode errorCode, const QString &errorMessage, const QString &guid);

    // Use this to enqueue a new job. It will automatically start it if there is no other job pending.
    void enqueue(EvernoteJob *job);
    void startJobQueue();

    // You should not use this. It's called by the job queue.
    // If you have a new job to run, just enqueue it. The queue will process it eventually.
    void startNextJob();

private:
    explicit NotesStore(QObject *parent = 0);
    static NotesStore *s_instance;

    QString m_token;

    QHash<QString, Notebook*> m_notebooks;
    QHash<QString, Note*> m_notes;

    // There must be only one job running at a time
    // Do not start jobs other than with startJobQueue()
    QList<EvernoteJob*> m_jobQueue;
    EvernoteJob *m_currentJob;

    // Those two are accessed from the job thread.
    // Make sure to not access them while any jobs are running
    // or we need to mutex them.
    evernote::edam::NoteStoreClient *m_client;
    boost::shared_ptr<THttpClient> m_httpClient;

};

#endif // NOTESSTORE_H
