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
    static NotesStore *instance();

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

private:
    explicit NotesStore(QObject *parent = 0);

private slots:
    void fetchNotesJobDone();
    void fetchNotebooksJobDone();
    void fetchNoteJobDone();

    void sendNextRequest();

signals:
    void tokenChanged();

    void noteAdded(const QString &guid);
    void noteChanged(const QString &guid);

    void notebookAdded(const QString &guid);

private:
    static NotesStore *s_instance;

    void displayException();

    QString m_token;
    evernote::edam::NoteStoreClient *m_client;

    QHash<QString, Notebook*> m_notebooks;
    QHash<QString, Note*> m_notes;

    QList<QThread*> m_requestQueue;
    QThread *m_currentJob;
    QHash<QObject*, evernote::edam::NotesMetadataList*> m_notesResultsMap;
    QHash<QObject*, std::vector<evernote::edam::Notebook>* > m_notebooksResultsMap;
    QHash<QObject*, evernote::edam::Note*> m_noteContentResultsMap;

};

#endif // NOTESSTORE_H
