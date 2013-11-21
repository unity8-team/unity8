#ifndef USERSTORE_H
#define USERSTORE_H

#include "UserStore.h"

#include <QObject>

using namespace evernote::edam;

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
