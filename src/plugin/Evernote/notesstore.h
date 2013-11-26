#ifndef NOTESSTORE_H
#define NOTESSTORE_H

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QObject>
#include <QHash>

class EvernoteJob;

class Notebook;
class Note;

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
    void fetchNotesJobDone(ErrorCode errorCode, const evernote::edam::NotesMetadataList &results);
    void fetchNotebooksJobDone(ErrorCode errorCode, const std::vector<evernote::edam::Notebook> &results);
    void fetchNoteJobDone(ErrorCode errorCode, const evernote::edam::Note &result);
    void createNoteJobDone(ErrorCode errorCode, Note *note);
    void saveNoteJobDone(ErrorCode errorCode, Note *note);
    void deleteNoteJobDone(ErrorCode errorCode, const QString &guid);

    void startJobQueue();
    void startNextJob();

private:
    explicit NotesStore(QObject *parent = 0);
    static NotesStore *s_instance;

    QString m_token;
    evernote::edam::NoteStoreClient *m_client;

    QHash<QString, Notebook*> m_notebooks;
    QHash<QString, Note*> m_notes;

    QList<EvernoteJob*> m_jobQueue;
    QThread *m_currentJob;
};

#endif // NOTESSTORE_H
