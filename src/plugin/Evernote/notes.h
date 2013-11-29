#ifndef NOTES_H
#define NOTES_H

#include "notesstore.h"

#include <QSortFilterProxyModel>

class Notes : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterNotebookGuid READ filterNotebookGuid WRITE setFilterNotebookGuid NOTIFY filterNotebookGuidChanged)
    Q_PROPERTY(bool onlyReminders READ onlyReminders WRITE setOnlyReminders NOTIFY onlyRemindersChanged)

public:
    explicit Notes(QObject *parent = 0);

    QString filterNotebookGuid() const;
    void setFilterNotebookGuid(const QString &notebookGuid);

    bool onlyReminders() const;
    void setOnlyReminders(bool onlyReminders);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

signals:
    void filterNotebookGuidChanged();
    void onlyRemindersChanged();

private:
    QString m_filterNotebookGuid;
    bool m_onlyReminders;

};

#endif // NOTES_H
