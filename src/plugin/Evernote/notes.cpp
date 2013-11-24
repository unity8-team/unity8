#include "notes.h"

#include <QDebug>

Notes::Notes(QObject *parent) :
    QAbstractListModel(parent)
{
    connect(NotesStore::instance(), SIGNAL(noteAdded(const QString &)), SLOT(noteAdded(const QString &)));
}

QVariant Notes::data(const QModelIndex &index, int role) const
{
    Note *note = NotesStore::instance()->note(m_list.at(index.row()));
    switch(role) {
    case RoleGuid:
        return note->guid();
    case RoleTitle:
        return note->title();
    }

    return QVariant();
}

int Notes::rowCount(const QModelIndex &parent) const
{
    return m_list.count();
}

QHash<int, QByteArray> Notes::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleTitle, "title");
    return roles;
}

QString Notes::filterNotebookGuid() const
{
    return m_filterNotebookGuid;
}

void Notes::setFilterNotebookGuid(const QString &notebookGuid)
{
    if (m_filterNotebookGuid != notebookGuid) {
        m_filterNotebookGuid = notebookGuid;
        emit filterNotebookGuidChanged();
    }
}

Note* Notes::note(const QString &guid)
{
    NotesStore::instance()->refreshNoteContent(guid);
    return NotesStore::instance()->note(guid);
}

void Notes::componentComplete()
{
    foreach (Note *note, NotesStore::instance()->notes()) {
        if (m_filterNotebookGuid.isEmpty() || note->notebookGuid() == m_filterNotebookGuid) {
            m_list.append(note->guid());
        }
    }
    beginInsertRows(QModelIndex(), 0, m_list.count() - 1);
    endInsertRows();
    refresh();
}

void Notes::refresh()
{
    NotesStore::instance()->refreshNotes(m_filterNotebookGuid);
}

void Notes::noteAdded(const QString &guid)
{
    beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
    m_list.append(guid);
    endInsertRows();
}

void Notes::noteChanged(const QString &guid)
{
    int row = m_list.indexOf(guid);
    if (row >= 0) {
        emit dataChanged(index(row), index(row));
    }
}
