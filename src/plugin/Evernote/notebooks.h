#ifndef NOTEBOOKS_H
#define NOTEBOOKS_H

#include "notesstore.h"

#include <QAbstractListModel>

using namespace evernote::edam;

class Notebooks : public QAbstractListModel
{
    Q_OBJECT
public:
    enum Roles {
        RoleGuid,
        RoleName
    };
    explicit Notebooks(QObject *parent = 0);

    QVariant data(const QModelIndex &index, int role) const;
    int rowCount(const QModelIndex &parent) const;
    QHash<int, QByteArray> roleNames() const;

public slots:
    void refresh();

private:
    std::vector<Notebook> m_list;


};

#endif // NOTEBOOKS_H
