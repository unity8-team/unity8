/*
 * Copyright: 2013 Canonical, Ltd
 *
 * This file is part of reminders-app
 *
 * reminders-app is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * reminders-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Authors: Michael Zanetti <michael.zanetti@canonical.com>
 */

#include "userstore.h"

// Evernote sdk
#include <UserStore.h>
#include <UserStore_constants.h>
#include <Errors_types.h>

// Thrift
#include <arpa/inet.h> // seems thrift forgot this one
#include <protocol/TBinaryProtocol.h>
#include <transport/THttpClient.h>
#include <transport/TSSLSocket.h>
#include <Thrift.h>

#include <QDebug>

using namespace evernote::edam;
using namespace apache::thrift;
using namespace apache::thrift::protocol;
using namespace apache::thrift::transport;

UserStore::UserStore(QObject *parent) :
    QObject(parent)
{

    try {
        // FIXME: need to populate this string from the system
        // The structure should be:
        // application/version; platform/version; [ device/version ]
        // E.g. "Evernote Windows/3.0.1; Windows/XP SP3"
        QString EDAM_CLIENT_NAME = QStringLiteral("Reminders/0.1; Ubuntu/13.10");
        QString EVERNOTE_HOST = QStringLiteral("sandbox.evernote.com");
        QString EDAM_USER_STORE_PATH = QStringLiteral("/edam/user");
        boost::shared_ptr<TSocket> socket;
        bool use_SSL = false;

        if (use_SSL) {
            // Create an SSL socket
            // FIXME: this fails with the following error:
            //   Thrift: Fri Nov 15 12:47:31 2013 SSL_shutdown: error code: 0
            //   SSL_get_verify_result(), unable to get local issuer certificate
            // Additionally, the UI blocks and does not load for about 2 minutes
            boost::shared_ptr<TSSLSocketFactory> sslSocketFactory(new TSSLSocketFactory());
            socket = sslSocketFactory->createSocket(EVERNOTE_HOST.toStdString(), 443);
        } else {
            // Create a non-secure socket
            socket = boost::shared_ptr<TSocket> (new TSocket(EVERNOTE_HOST.toStdString(), 80));
        }

        boost::shared_ptr<TBufferedTransport> bufferedTransport(new TBufferedTransport(socket));
        boost::shared_ptr<THttpClient> userStoreHttpClient (new THttpClient(bufferedTransport,
                                                                            EVERNOTE_HOST.toStdString(),
                                                                            EDAM_USER_STORE_PATH.toStdString()));
        userStoreHttpClient->open();

        boost::shared_ptr<TProtocol> iprot(new TBinaryProtocol(userStoreHttpClient));
        UserStoreClient m_client(iprot);
        UserStoreConstants constants;

        // checkVersion returns true if the client is capable of talking to the service,
        // false otherwise
        qDebug() << "version check:" << m_client.checkVersion(EDAM_CLIENT_NAME.toStdString(),
                                                              constants.EDAM_VERSION_MAJOR,
                                                              constants.EDAM_VERSION_MINOR);

    } catch(...) {
        displayException();
    }
}

void UserStore::getPublicUserInfo(const QString &user)
{
    qDebug() << "should get public user info for user" << user;
    //    PublicUserInfo userInfo;

}

// TODO: move to a common place instead of copying it through *store.cpps
void UserStore::displayException()
{
    QString error_message = "Unknown Exception";
    try
    {
        // this function is meant to be called from a catch block
        // rethrow the exception to catch it again
        throw;
    }
    catch (const EDAMNotFoundException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const EDAMSystemException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const EDAMUserException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const TTransportException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const TException & e)
    {
        qDebug() <<  e.what();
    }
    catch (const std::exception & e)
    {
        qDebug() <<  e.what();
    }
    catch (...)
    {
        error_message = "Tried to sync, but something went wrong.\n Unknown exception.";
    }

    qDebug() << error_message;
    disconnect();
}
