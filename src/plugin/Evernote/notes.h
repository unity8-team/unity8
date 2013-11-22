#ifndef NOTES_H
#define NOTES_H

#include "notesstore.h"

#include <QAbstractListModel>

using namespace evernote::edam;

class Notes : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterNotebookGuid READ filterNotebookGuid WRITE setFilterNotebookGuid NOTIFY filterNotebookGuidChanged)
public:
    enum Roles {
        RoleGuid,
        RoleTitle
    };
    explicit Notes(QObject *parent = 0);

    QVariant data(const QModelIndex &index, int role) const;
    int rowCount(const QModelIndex &parent) const;
    QHash<int, QByteArray> roleNames() const;

    QString filterNotebookGuid() const;
    void setFilterNotebookGuid(const QString &notebookGuid);

    Q_INVOKABLE QString note(const QString &noteGuid);

public slots:
    void refresh();

signals:
    void filterNotebookGuidChanged();

private:
    QList<NoteMetadata> m_list;
    QString m_filterNotebookGuid;

};

#endif // NOTES_H
