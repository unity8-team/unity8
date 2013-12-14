#ifndef NOTEBOOK_H
#define NOTEBOOK_H

#include <QObject>

class Notebook : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString guid READ guid CONSTANT)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(int noteCount READ noteCount NOTIFY noteCountChanged)
    Q_PROPERTY(bool published READ published NOTIFY publishedChanged)

public:
    explicit Notebook(QString guid, QObject *parent = 0);

    QString guid() const;

    QString name() const;
    void setName(const QString &name);

    int noteCount() const;

    bool published() const;
    void setPublished(bool published);

signals:
    void nameChanged();
    void noteCountChanged();
    void publishedChanged();

private slots:
    void noteAdded(const QString &noteGuid, const QString &notebookGuid);
    void noteRemoved(const QString &noteGuid, const QString &notebookGuid);

private:
    QString m_guid;
    QString m_name;
    int m_noteCount;
    bool m_published;
};

#endif // NOTEBOOK_H
