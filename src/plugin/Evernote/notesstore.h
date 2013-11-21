#ifndef NOTESSTORE_H
#define NOTESSTORE_H

// Evernote SDK
#include <NoteStore.h>
#include <NoteStore_constants.h>
#include <Errors_types.h>

// Qt
#include <QObject>

using namespace evernote::edam;

class Notebooks;

class NotesStore : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString token READ token WRITE setToken NOTIFY tokenChanged)

public:
    static NotesStore *instance();

    ~NotesStore();

    QString token() const;
    void setToken(const QString &token);

    NoteStoreClient *evernoteNotesStoreClient();

private:
    explicit NotesStore(QObject *parent = 0);

signals:
    void tokenChanged();

private:
    static NotesStore *s_instance;

    void displayException();

    QString m_token;
    NoteStoreClient *m_client;

};

#endif // NOTESSTORE_H
