#ifndef NOTES_H
#define NOTES_H

#include "notesstore.h"

#include <QAbstractListModel>
#include <QQmlParserStatus>

class Notes : public QAbstractListModel, public QQmlParserStatus
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

    Q_INVOKABLE Note* note(const QString &guid);

    void classBegin() {}
    void componentComplete();

public slots:
    void refresh();

private slots:
    void noteAdded(const QString &guid);
    void noteChanged(const QString &guid);
    void noteRemoved(const QString &guid);

signals:
    void filterNotebookGuidChanged();

private:
    QList<QString> m_list;
    QString m_filterNotebookGuid;

};

#endif // NOTES_H
