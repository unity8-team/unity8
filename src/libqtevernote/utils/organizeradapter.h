#ifndef ORGANIZERADAPTER_H
#define ORGANIZERADAPTER_H

#include "note.h"

#include <QObject>

#include <QOrganizerManager>
#include <QOrganizerCollection>
#include <QOrganizerTodo>
#include <QOrganizerAbstractRequest>

QTORGANIZER_USE_NAMESPACE

class OrganizerAdapter: public QObject
{
    Q_OBJECT
public:
    OrganizerAdapter(QObject *parent = 0);

    void startSync();
    bool busy() const;

private slots:
    void fetchStateChanged(QOrganizerAbstractRequest::State state);
    void writeStateChanged(QOrganizerAbstractRequest::State state);
    void deleteStateChanged(QOrganizerAbstractRequest::State state);

private:
    void organizerEventFromNote(Note *note, QOrganizerTodo &item);
    void loadReminders();
    void writeReminders();

    QOrganizerManager *m_manager;
    QOrganizerCollection m_collection;
    bool m_busy;
    bool m_restart;
};

#endif
