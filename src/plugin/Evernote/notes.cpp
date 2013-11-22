#include "notes.h"

#include <QDebug>

Notes::Notes(QObject *parent) :
    QAbstractListModel(parent)
{
}

QVariant Notes::data(const QModelIndex &index, int role) const
{
    switch(role) {
    case RoleGuid:
        return QString::fromStdString(m_list.at(index.row()).guid);
    case RoleTitle:
        return QString::fromStdString(m_list.at(index.row()).title);
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

QString Notes::note(const QString &noteGuid)
{
    QString token = NotesStore::instance()->token();
    if (token.isEmpty()) {
        qDebug() << "No token set. Cannot fetch note.";
        return QString();
    }

    Note note;
    try {
        NotesStore::instance()->evernoteNotesStoreClient()->getNote(note, token.toStdString(), noteGuid.toStdString(), true, true, false, false);
    } catch(...) {
        qDebug() << "error fetching note";
        return QString();
    }

    return QString::fromStdString(note.content);
}

void Notes::refresh()
{
    QString token = NotesStore::instance()->token();
    if (token.isEmpty()) {
        qDebug() << "No token set. Cannot fetch notes.";
        return;
    }

    int32_t start = 0;
    int32_t end = 10000;

    // Prepare filter
    NoteFilter filter;
    filter.notebookGuid = m_filterNotebookGuid.toStdString();
    filter.__isset.notebookGuid = !m_filterNotebookGuid.isEmpty();

    // Prepare ResultSpec
    NotesMetadataResultSpec resultSpec;
    resultSpec.includeTitle = true;
    resultSpec.__isset.includeTitle = true;

    NotesMetadataList notes;
    try {
        NotesStore::instance()->evernoteNotesStoreClient()->findNotesMetadata(notes, token.toStdString(), filter, start, end, resultSpec);
    } catch(...) {
        qDebug() << "error fetching notes";
        return;
    }

    beginResetModel();
    m_list.clear();
    foreach (NoteMetadata note, notes.notes) {
        m_list.append(note);
        qDebug() << QString::fromStdString(note.guid) << QString::fromStdString(note.title);
    }
    endResetModel();
}
