/*
 * Copyright 2013-2015 Canonical Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <QtTest>
#include <QDBusConnection>
#include <QDBusMessage>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDBusVariant>
#include <QDebug>
#include <QDBusObjectPath>

#include <unistd.h>
#include <sys/types.h>

#include "dbusunitysessionservice.h"

enum class Action : unsigned
{
  LOGOUT = 0,
  SHUTDOWN,
  REBOOT,
  NONE
};

class SessionBackendTest : public QObject
{
    Q_OBJECT

private Q_SLOTS:

    void initTestCase() {
        dbusUnitySession = new QDBusInterface ("com.canonical.Unity",
                                               "/com/canonical/Unity/Session",
                                               "com.canonical.Unity.Session",
                                               QDBusConnection::sessionBus(), this);

        // logind mock
        m_fakeLogindServer = new QProcess;
        m_fakeLogindServer->start("python3 -m dbusmock org.freedesktop.login1 /org/freedesktop/login1 org.freedesktop.login1.Manager");
        m_fakeLogindServer->waitForStarted();
        qDebug() << "Logind DBUS mock started with pid:" << m_fakeLogindServer->processId();

        m_logindMockIface = new QDBusInterface("org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.DBus.Mock",
                                               QDBusConnection::sessionBus(), this);
        QTRY_VERIFY(m_logindMockIface->isValid());

        m_logindMockIface->call("AddTemplate", "logind", QVariant::fromValue(QVariantMap())); // load the logind template, no params

        // add a fake session to make DBusUnitySessionService happy
        QDBusReply<QString> fakeSession = m_logindMockIface->call("AddSession", "fakesession", "fakeseat", (quint32) getuid(),
                                                                  "fakeuser", true);

        qDebug() << "Using a fake login1 session:" << fakeSession;

        if (!fakeSession.isValid()) {
            qWarning() << "Fake session error:" << fakeSession.error().name() << ":" << fakeSession.error().message();
            QFAIL("Fake session could not be found");
        }
        m_logindMockIface->call("AddMethod", "org.freedesktop.login1.Manager", "GetSessionByPID", "u", "o",
                                QStringLiteral("ret='%1'").arg(fakeSession)); // let DBUSS find the fake session to operate on

        // gnome screensaver mock
        m_fakeGnomeScreensaverServer = new QProcess;
        m_fakeGnomeScreensaverServer->start("python3 -m dbusmock org.gnome.ScreenSaver /org/gnome/ScreenSaver org.gnome.ScreenSaver");
        m_fakeGnomeScreensaverServer->waitForStarted();
        qDebug() << "Gnome screensaver DBUS mock started with pid:" << m_fakeGnomeScreensaverServer->processId();

        m_gnomeScreensaverMockIface = new QDBusInterface("org.gnome.ScreenSaver", "/org/gnome/ScreenSaver", "org.freedesktop.DBus.Mock",
                                                         QDBusConnection::sessionBus(), this);
        QTRY_VERIFY(m_gnomeScreensaverMockIface->isValid());

        m_gnomeScreensaverMockIface->call("AddTemplate", "gnome_screensaver", QVariant::fromValue(QVariantMap())); // load the gnome ss template, no params
    }

    void cleanupTestCase() {
        m_fakeLogindServer->kill();
        delete m_fakeLogindServer;

        m_fakeGnomeScreensaverServer->kill();
        delete m_fakeGnomeScreensaverServer;
    }

    void testUnitySessionService_data() {
        QTest::addColumn<QString>("method");
        QTest::addColumn<QString>("signal");

        QTest::newRow("Logout") << "RequestLogout" << "LogoutRequested(bool)";
        QTest::newRow("Reboot") << "RequestReboot" << "RebootRequested(bool)";
        QTest::newRow("Shutdown") << "RequestShutdown" << "ShutdownRequested(bool)";
        QTest::newRow("PromptLock") << "PromptLock" << "LockRequested()";
    }

    void testUnitySessionService() {
        QFETCH(QString, method);
        QFETCH(QString, signal);

        DBusUnitySessionService dbusUnitySessionService;
        QCoreApplication::processEvents(); // to let the service register on DBus

        // .. because QSignalSpy checks the signal signature like this: "if (((aSignal[0] - '0') & 0x03) != QSIGNAL_CODE)"
        QSignalSpy spy(&dbusUnitySessionService, qPrintable(signal.prepend(QSIGNAL_CODE)));

        QDBusReply<void> reply = dbusUnitySession->call(method);
        QCOMPARE(reply.isValid(), true);

        QCOMPARE(spy.count(), 1);
    }

    void testGnomeSessionWrapper_data() {
        QTest::addColumn<uint>("method");
        QTest::addColumn<QString>("signal");

        QTest::newRow("Logout") << (uint)Action::LOGOUT << "LogoutRequested(bool)";
        QTest::newRow("Shutdown") << (uint)Action::SHUTDOWN << "ShutdownRequested(bool)";
        QTest::newRow("Reboot") << (uint)Action::REBOOT << "RebootRequested(bool)";
    }

    void testGnomeSessionWrapper() {
        QFETCH(uint, method);
        QFETCH(QString, signal);

        DBusUnitySessionService dbusUnitySessionService;
        QCoreApplication::processEvents(); // to let the service register on DBus

        // Spy on the given signal on the /com/canonical/Unity/Session object
        // as proof we are actually calling the actual method.
        // .. because QSignalSpy checks the signal signature like this: "if (((aSignal[0] - '0') & 0x03) != QSIGNAL_CODE)"
        QSignalSpy spy(&dbusUnitySessionService, qPrintable(signal.prepend(QSIGNAL_CODE)));

        DBusGnomeSessionManagerWrapper dbusGnomeSessionManagerWrapper;
        QCoreApplication::processEvents(); // to let the service register on DBus

        QDBusInterface dbusGnomeSessionWrapper("com.canonical.Unity",
                                               "/org/gnome/SessionManager/EndSessionDialog",
                                               "org.gnome.SessionManager.EndSessionDialog",
                                               QDBusConnection::sessionBus());

        QCOMPARE(dbusGnomeSessionWrapper.isValid(), true);

        // Set the QVariant as a QList<QDBusObjectPath> type
        QDbusList var;
        QVariant inhibitors;
        inhibitors.setValue(var);

        QDBusReply<void> reply = dbusGnomeSessionWrapper.call("Open", method, (unsigned)0, (unsigned)0, inhibitors);
        QCOMPARE(reply.isValid(), true);

        // Make sure we see the signal being emitted.
        QCOMPARE(spy.count(), 1);
    }

    void testUserName() {
        DBusUnitySessionService dbusUnitySessionService;
        QCoreApplication::processEvents(); // to let the service register on DBus

        QProcess * proc = new QProcess(this);
        proc->start("id -un", QProcess::ReadOnly);
        proc->waitForFinished();
        const QByteArray out = proc->readAll().trimmed();

        QCOMPARE(dbusUnitySessionService.UserName(), QString::fromUtf8(out));
    }

    void testRealName() {
        DBusUnitySessionService dbusUnitySessionService;
        QCoreApplication::processEvents(); // to let the service register on DBus

        QDBusInterface accIface("org.freedesktop.Accounts", "/org/freedesktop/Accounts", "org.freedesktop.Accounts", QDBusConnection::systemBus());
        if (accIface.isValid()) {
            QDBusReply<QDBusObjectPath> userPath = accIface.asyncCall("FindUserById", static_cast<qint64>(geteuid()));
            if (userPath.isValid()) {
                QDBusInterface userAccIface("org.freedesktop.Accounts", userPath.value().path(), "org.freedesktop.Accounts.User", QDBusConnection::systemBus());
                QCOMPARE(dbusUnitySessionService.RealName(), userAccIface.property("RealName").toString());
            }
        }
    }

    void testLogin1Capabilities_data() {
        QTest::addColumn<QString>("dbusMethod"); // dbus method on the login1 iface
        QTest::addColumn<QString>("method");     // our method

        QTest::newRow("CanHibernate") << "CanHibernate" << "CanHibernate";
        QTest::newRow("CanSuspend") << "CanSuspend" << "CanSuspend";
        QTest::newRow("CanReboot") << "CanReboot" << "CanReboot";
        QTest::newRow("CanPowerOff") << "CanPowerOff" << "CanShutdown";
        QTest::newRow("CanHybridSleep") << "CanHybridSleep" << "CanHybridSleep";
    }

    void testLogin1Capabilities() {
        QFETCH(QString, dbusMethod);
        QFETCH(QString, method);

        DBusUnitySessionService dbusUnitySessionService;
        QDBusInterface login1face("org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", QDBusConnection::SM_BUSNAME());
        QCoreApplication::processEvents(); // to let the services register on DBus

        QDBusReply<QString> dbusReply = login1face.call(dbusMethod);
        bool reply;
        dbusUnitySessionService.metaObject()->invokeMethod(&dbusUnitySessionService, qPrintable(method), Q_RETURN_ARG(bool, reply));
        QCOMPARE(reply, (dbusReply == "yes" || dbusReply == "challenge"));
    }

    void testLogindMock_data() {
        QTest::addColumn<QString>("method"); // dbus method on the login1 iface

        QTest::newRow("CanHibernate") << "CanHibernate";
        QTest::newRow("CanSuspend") << "CanSuspend";
        QTest::newRow("CanReboot") << "CanReboot";
        QTest::newRow("CanPowerOff") << "CanPowerOff";
        QTest::newRow("CanHybridSleep") << "CanHybridSleep";
    }

    void testLogindMock() {
        QFETCH(QString, method);

        const QStringList replies = {"yes", "no", "na", "challenge"};

        Q_FOREACH(const QString &reply, replies) {
            m_logindMockIface->call("AddMethod", "org.freedesktop.login1.Manager", method, "", "s",
                                    QStringLiteral("ret='%1'").arg(reply));

            QDBusInterface login1face("org.freedesktop.login1", "/org/freedesktop/login1", "org.freedesktop.login1.Manager", QDBusConnection::SM_BUSNAME());
            QCoreApplication::processEvents(); // to let the services register on DBus

            QDBusReply<QString> dbusReply = login1face.call(method);

            QCOMPARE(dbusReply.value(), reply);
        }
    }

    void testGnomeScreenSaverMock() {
        QDBusInterface gnomeSaverIface("org.gnome.ScreenSaver", "/org/gnome/ScreenSaver", "org.gnome.ScreenSaver",
                                       QDBusConnection::sessionBus(), this);
        QCoreApplication::processEvents(); // to let the service register on DBus

        gnomeSaverIface.call("Lock");

        QDBusReply<bool> isActive = gnomeSaverIface.call("GetActive");

        QTRY_VERIFY(isActive.value()); // verify it's active (locked)
    }

private:
    QDBusInterface *dbusUnitySession;

    QProcess *m_fakeLogindServer = nullptr;
    QDBusInterface *m_logindMockIface = nullptr;

    QProcess *m_fakeGnomeScreensaverServer = nullptr;
    QDBusInterface *m_gnomeScreensaverMockIface = nullptr;
};

QTEST_GUILESS_MAIN(SessionBackendTest)
#include "sessionbackendtest.moc"
