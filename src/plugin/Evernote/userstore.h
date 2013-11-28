#ifndef USERSTORE_H
#define USERSTORE_H

#include "evernoteconnection.h"

//Evernote SDK
#include "UserStore.h"

#include <QObject>

class UserStore : public QObject
{
    Q_OBJECT

    // TODO: Once we need more than just the username, turn this into a class User
    Q_PROPERTY(QString username READ username NOTIFY usernameChanged)

public:
    static UserStore* instance();

    QString username() const;

signals:
    void usernameChanged();

private slots:
    void fetchUsername();

    void fetchUsernameJobDone(EvernoteConnection::ErrorCode errorCode, const QString &errorMessage, const QString &result);

private:
    static UserStore* s_instance;
    explicit UserStore(QObject *parent = 0);

    QString m_username;
};

#endif // USERSTORE_H
