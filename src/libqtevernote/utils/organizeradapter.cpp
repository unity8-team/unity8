#include "organizeradapter.h"
#include "notesstore.h"
#include "logging.h"

#include <QDebug>
#include <QOrganizerItemVisualReminder>
#include <QOrganizerItemAudibleReminder>
#include <QOrganizerItemSaveRequest>
#include <QOrganizerItemFetchRequest>
#include <QOrganizerItemRemoveRequest>
#include <QOrganizerItemCollectionFilter>
#include <QOrganizerTodoTime>
#include <QOrganizerItem>

QTORGANIZER_USE_NAMESPACE

#define ALARM_MANAGER           "eds"
#define ALARM_MANAGER_FALLBACK  "memory"
#define ALARM_COLLECTION        "Reminders"


OrganizerAdapter::OrganizerAdapter(QObject *parent):
    QObject(parent),
    m_busy(false)
{

    QString envManager(qgetenv("ALARM_BACKEND"));
    if (envManager.isEmpty())
        envManager = ALARM_MANAGER;
    if (!QOrganizerManager::availableManagers().contains(envManager)) {
        envManager = ALARM_MANAGER_FALLBACK;
    }
    m_manager = new QOrganizerManager(envManager);
    m_manager->setParent(this);

    QList<QOrganizerCollection> collections = m_manager->collections();
    if (collections.count() > 0) {
        Q_FOREACH(const QOrganizerCollection &c, collections) {
            if (c.metaData(QOrganizerCollection::KeyName).toString() == ALARM_COLLECTION) {
                m_collection = c;
                break;
            }
        }
    }
    if (m_collection.id().isNull()) {
        // create alarm collection
        m_collection.setMetaData(QOrganizerCollection::KeyName, ALARM_COLLECTION);
        // EDS requires extra metadata to be set
        m_collection.setExtendedMetaData("collection-type", "Task List");
        if (!m_manager->saveCollection(&m_collection)) {
            qCWarning(dcOrganizer) << "WARNING: Creating dedicated collection for reminders was not possible, reminders will be saved into the default collection!";
            m_collection = m_manager->defaultCollection();
        }
    }

    qCDebug(dcOrganizer) << "Have Organizer collection" << m_collection.id().toString();
}

void OrganizerAdapter::startSync()
{
    if (m_busy) {
        m_restart = true;
        return;
    }
    m_restart = false;
    m_busy = true;
    loadReminders();
}

void OrganizerAdapter::writeReminders()
{
    foreach (Note* note, NotesStore::instance()->notes()) {
        if (note->reminder() && note->hasReminderTime() && !note->reminderDone() && !note->deleted()) {
            QOrganizerTodo item;
            organizerEventFromNote(note, item);

            QOrganizerItemSaveRequest *operation = new QOrganizerItemSaveRequest(this);
            operation->setManager(m_manager);
            operation->setItem(item);
            connect(operation, &QOrganizerItemFetchRequest::stateChanged, this, &OrganizerAdapter::writeStateChanged);
            operation->start();
        }
    }
}

void OrganizerAdapter::organizerEventFromNote(Note *note, QOrganizerTodo &item)
{
    item.setCollectionId(m_collection.id());
    item.setAllDay(false);
    item.setStartDateTime(note->reminderTime().toUTC());
    item.setDisplayLabel(note->title());
    item.setDescription(note->guid());

    QOrganizerItemVisualReminder visual;
    visual.setSecondsBeforeStart(0);
    visual.setMessage(note->title());
    item.saveDetail(&visual);

    QOrganizerItemAudibleReminder audible;
    audible.setSecondsBeforeStart(0);
    //audible.setDataUrl(alarm.sound);
    item.saveDetail(&audible);
}

void OrganizerAdapter::loadReminders()
{
    QOrganizerItemFetchRequest *operation = new QOrganizerItemFetchRequest(this);
    operation->setManager(m_manager);

    // set sort order
    QOrganizerItemSortOrder sortOrder;
    sortOrder.setDirection(Qt::AscendingOrder);
    sortOrder.setDetail(QOrganizerItemDetail::TypeTodoTime, QOrganizerTodoTime::FieldStartDateTime);
    operation->setSorting(QList<QOrganizerItemSortOrder>() << sortOrder);

    // set filter
    QOrganizerItemCollectionFilter filter;
    filter.setCollectionId(m_collection.id());
    operation->setFilter(filter);

    // start request
    connect(operation, &QOrganizerItemFetchRequest::stateChanged, this, &OrganizerAdapter::fetchStateChanged);
    operation->start();
}

void OrganizerAdapter::fetchStateChanged(QOrganizerAbstractRequest::State state)
{
    QOrganizerItemFetchRequest *request = static_cast<QOrganizerItemFetchRequest*>(sender());

    if (m_restart) {
        m_busy = false;
        startSync();
        return;
    }

    if (state == QOrganizerAbstractRequest::CanceledState) {
        qCWarning(dcOrganizer) << "Error syncing reminders. Could not read organizer items.";
        m_busy = false;
        request->deleteLater();
        return;
    }

    // cleaning up old reminders
    if (state == QOrganizerAbstractRequest::FinishedState) {
         QList<QOrganizerItem> items = request->items();
         foreach (const QOrganizerItem &item, items) {
             QOrganizerItemRemoveRequest *removeRequest = new QOrganizerItemRemoveRequest(this);
             removeRequest->setItem(item);
             removeRequest->setManager(m_manager);
             connect(removeRequest, &QOrganizerItemRemoveRequest::stateChanged, this, &OrganizerAdapter::deleteStateChanged);
             removeRequest->start();
         }
         request->deleteLater();
         writeReminders();
         m_busy = false;
    }
}

void OrganizerAdapter::writeStateChanged(QOrganizerAbstractRequest::State state)
{
    QOrganizerItemSaveRequest *request = static_cast<QOrganizerItemSaveRequest*>(sender());
    if (state == QOrganizerAbstractRequest::FinishedState || state == QOrganizerAbstractRequest::CanceledState) {
        request->deleteLater();
    }
}

void OrganizerAdapter::deleteStateChanged(QOrganizerAbstractRequest::State state)
{
    QOrganizerItemSaveRequest *request = static_cast<QOrganizerItemSaveRequest*>(sender());
    if (state == QOrganizerAbstractRequest::FinishedState || state == QOrganizerAbstractRequest::CanceledState) {
        request->deleteLater();
    }
}
