#include "core.h"

#include "evernoteconnection.h"
#include "notesstore.h"
#include "note.h"

#include <QDebug>
#include <QOrganizerEvent>

Core::Core(QObject *parent):
    QObject(parent)
{
    qDebug() << "Core starting up";
    connect(EvernoteConnection::instance(), &EvernoteConnection::isConnectedChanged, this, &Core::connectedChanged);
    qDebug() << "EvernoteConnection created";
    connect(NotesStore::instance(), &NotesStore::loadingChanged, this, &Core::notesLoaded);
    qDebug() << "notestore created";
//    connect(&m_oaSetup, &OnlineAccountsClient::Setup::finished, this, &Core::oaRequestFinished);


//    m_oaSetup.setApplicationId("com.ubuntu.reminders_reminders");
//    m_oaSetup.setServiceTypeId("evernote");
//    m_oaSetup.exec();
//    qDebug() << "OA request started";

    EvernoteConnection::instance()->setToken("S=s358:U=39eb980:E=1516e9a3575:C=14a16e90690:P=185:A=canonicalis:V=2:H=737f36850d4943e61ff2fcf7b4c809e2");
    EvernoteConnection::instance()->setHostname("www.evernote.com");

    qDebug() << "Core created";
}

void Core::process(const QByteArray &pushNotification)
{
    qDebug() << "should process:" << pushNotification;
}

void Core::connectedChanged()
{
    if (!EvernoteConnection::instance()->isConnected()) {
        qWarning() << "Disconnected from Evernote.";
        return;
    }

    qDebug() << "Connected to Evernote.";
}

void Core::notesLoaded()
{
    qDebug() << "notes loading changed:" << NotesStore::instance()->loading();
    foreach (Note *note, NotesStore::instance()->notes()) {
        qDebug() << "have note" << note->title();
        qDebug() << "content:" << note->plaintextContent();
    }
}

void Core::oaRequestFinished(const QVariantMap &reply)
{
    qDebug() << "OA reply" << reply;
}
