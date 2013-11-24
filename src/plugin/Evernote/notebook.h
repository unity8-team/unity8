#ifndef NOTEBOOK_H
#define NOTEBOOK_H

#include <QObject>

class Notebook : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString guid READ guid CONSTANT)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
public:
    explicit Notebook(QString guid, QObject *parent = 0);

    QString guid() const;

    QString name() const;
    void setName(const QString &name);

signals:
    void nameChanged();

public slots:

private:
    QString m_guid;
    QString m_name;
};

#endif // NOTEBOOK_H
