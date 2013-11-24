#include "notebooks.h"
#include "notebook.h"

#include <QDebug>

Notebooks::Notebooks(QObject *parent) :
    QAbstractListModel(parent)
{
    foreach (Notebook *notebook, NotesStore::instance()->notebooks()) {
        m_list.append(notebook->guid());
    }

    connect(NotesStore::instance(), SIGNAL(notebookAdded(const QString &)), SLOT(notebookAdded(const QString &)));
}

QVariant Notebooks::data(const QModelIndex &index, int role) const
{

    Notebook *notebook = NotesStore::instance()->notebook(m_list.at(index.row()));
    switch(role) {
    case RoleGuid:
        return notebook->guid();
    case RoleName:
        return notebook->name();
    }
    return QVariant();
}

int Notebooks::rowCount(const QModelIndex &parent) const
{
    return m_list.count();
}

QHash<int, QByteArray> Notebooks::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles.insert(RoleGuid, "guid");
    roles.insert(RoleName, "name");
    return roles;
}

void Notebooks::refresh()
{
    qDebug() << "refreshing notebooks";
    NotesStore::instance()->refreshNotebooks();
}

void Notebooks::notebookAdded(const QString &guid)
{
    beginInsertRows(QModelIndex(), m_list.count(), m_list.count());
    m_list.append(guid);
    endInsertRows();
}
