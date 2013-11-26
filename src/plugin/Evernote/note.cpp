#include "note.h"

#include "notesstore.h"

Note::Note(const QString &guid, QObject *parent) :
    QObject(parent),
    m_guid(guid)
{
}

QString Note::guid() const
{
    return m_guid;
}

void Note::setGuid(const QString &guid)
{
    if (m_guid == guid) {
        m_guid = guid;
        emit guidChanged();
    }
}

QString Note::notebookGuid() const
{
    return m_notebookGuid;
}

void Note::setNotebookGuid(const QString &notebookGuid)
{
    if (m_notebookGuid != notebookGuid) {
        m_notebookGuid = notebookGuid;
        emit notebookGuidChanged();
    }
}

QString Note::title() const
{
    return m_title;
}

void Note::setTitle(const QString &title)
{
    if (m_title != title) {
        m_title = title;
        emit titleChanged();
    }
}

QString Note::content() const
{
    return m_content;
}

void Note::setContent(const QString &content)
{
    if (m_content != content) {
        m_content = content;
        emit contentChanged();
    }
}

void Note::save()
{
    NotesStore::instance()->saveNote(m_guid);
}

void Note::remove()
{
    NotesStore::instance()->deleteNote(m_guid);
}
