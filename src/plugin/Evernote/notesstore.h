#ifndef NOTESSTORE_H
#define NOTESSTORE_H

#include "note.h"

#include <QObject>
#include <QHash>

class Notebook;
class Note;

namespace evernote {
namespace edam {
class NoteStoreClient;
}
}

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

};

#endif // NOTESSTORE_H
