#ifndef NOTESSTORE_H
#define NOTESSTORE_H

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

#include <QObject>
#include <QHash>

class Notebook;
class Note;

class NotesStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString token READ token WRITE setToken NOTIFY tokenChanged)

public:
    enum ErrorCode {
        ErrorCodeNoError,
        ErrorCodeUserException,
        ErrorCodeSystemException,
        ErrorCodeNotFoundExcpetion
    };

    static NotesStore *instance();
    static QString errorCodeToString(ErrorCode errorCode);

    ~NotesStore();

    QString token() const;
    void setToken(const QString &token);

    QList<Note*> notes() const;
    Note* note(const QString &guid);

    QList<Notebook*> notebooks() const;
    Notebook* notebook(const QString &guid);

    void refreshNotes(const QString &filterNotebookGuid = QString());
    void refreshNoteContent(const QString &guid);
    void refreshNotebooks();

signals:
    void tokenChanged();

    void noteAdded(const QString &guid);
    void noteChanged(const QString &guid);

    void notebookAdded(const QString &guid);

private slots:
    void fetchNotesJobDone(ErrorCode errorCode, const evernote::edam::NotesMetadataList &results);
    void fetchNotebooksJobDone(ErrorCode errorCode, const std::vector<evernote::edam::Notebook> &results);
    void fetchNoteJobDone(ErrorCode errorCode, const evernote::edam::Note &result);

    void startJobQueue();
    void startNextJob();

private:
    explicit NotesStore(QObject *parent = 0);
    static NotesStore *s_instance;

    QString m_token;
    evernote::edam::NoteStoreClient *m_client;

    QHash<QString, Notebook*> m_notebooks;
    QHash<QString, Note*> m_notes;

    QList<QThread*> m_requestQueue;
    QThread *m_currentJob;
};

#endif // NOTESSTORE_H
