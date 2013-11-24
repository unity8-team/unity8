#include "note.h"

Note::Note(const QString &guid, QObject *parent) :
    QObject(parent),
    m_guid(guid)
{
}

QString Note::guid() const
{
    return m_guid;
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
