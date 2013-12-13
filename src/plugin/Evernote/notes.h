#ifndef NOTES_H
#define NOTES_H

#include "notesstore.h"

#include <QSortFilterProxyModel>

class Notes : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QString filterNotebookGuid READ filterNotebookGuid WRITE setFilterNotebookGuid NOTIFY filterNotebookGuidChanged)
    Q_PROPERTY(bool onlyReminders READ onlyReminders WRITE setOnlyReminders NOTIFY onlyRemindersChanged)
    Q_PROPERTY(bool onlySearchResults READ onlySearchResults WRITE setOnlySearchResults NOTIFY onlySearchResultsChanged)

public:
    explicit Notes(QObject *parent = 0);

    QString filterNotebookGuid() const;
    void setFilterNotebookGuid(const QString &notebookGuid);

    bool onlyReminders() const;
    void setOnlyReminders(bool onlyReminders);

    bool onlySearchResults() const;
    void setOnlySearchResults(bool onlySearchResults);

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const;

signals:
    void filterNotebookGuidChanged();
    void onlyRemindersChanged();
    void onlySearchResultsChanged();

private:
    QString m_filterNotebookGuid;
    bool m_onlyReminders;
    bool m_onlySearchResults;
};

#endif // NOTES_H
