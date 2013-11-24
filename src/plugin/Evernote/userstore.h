#ifndef USERSTORE_H
#define USERSTORE_H

#include "UserStore.h"

#include <QObject>

class UserStore : public QObject
{
    Q_OBJECT
public:
    explicit UserStore(QObject *parent = 0);

signals:

public slots:
    void getPublicUserInfo(const QString &user);

private:

    void displayException();
};

#endif // USERSTORE_H
