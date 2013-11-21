#include "notebooks.h"

#include <QDebug>

Notebooks::Notebooks(QObject *parent) :
    QAbstractListModel(parent)
{
}

QVariant Notebooks::data(const QModelIndex &index, int role) const
{
    switch(role) {
    case RoleGuid:
        return QString::fromStdString(m_list.at(index.row()).guid);
    case RoleName:
        return QString::fromStdString(m_list.at(index.row()).name);
    }

    return QVariant();
}

int Notebooks::rowCount(const QModelIndex &parent) const
{
    return m_list.size();
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

    QString token = NotesStore::instance()->token();
    if (token.isEmpty()) {
        qDebug() << "No token set. Cannot fetch notebooks.";
        return;
    }

    beginResetModel();
    try {
        NotesStore::instance()->evernoteNotesStoreClient()->listNotebooks(m_list, token.toStdString());
    } catch(...) {
        qDebug() << "Error fetching notebooks.";
//        displayException();
    }

    endResetModel();

//    for (int i = 0; i < notebooks.size(); ++i) {
//        qDebug() << "got notebooks" << QString::fromStdString(notebooks.at(i).name) << QString::fromStdString(notebooks.at(i).name)
//                 << QString::fromStdString(notebooks.at(i).guid);
//    }
}
