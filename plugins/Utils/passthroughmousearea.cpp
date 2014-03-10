/*
 * Copyright (C) 2014 Canonical, Ltd.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "passthroughmousearea.h"
#include <QCoreApplication>
#include <QQuickWindow>

PassthroughMouseArea::PassthroughMouseArea(QQuickItem* parent)
:   QQuickMouseArea(parent),
    m_enabledEvents(true)
{
}

PassthroughMouseArea::~PassthroughMouseArea()
{
}

void PassthroughMouseArea::mousePressEvent(QMouseEvent *event)
{
    // Don't accept on second pass if we've already accepted on first pass
    // Keeps going down the stack...
    if (!m_enabledEvents) {
        event->setAccepted(false);
        return;
    }

    clearConnected();

    QQuickMouseArea::mousePressEvent(event);
    if (event->isAccepted()) {
        m_enabledEvents = false;

        QQuickWindow* w = window();
        if (!w) {
            m_enabledEvents = true;
            return;
        }

        if (w->mouseGrabberItem() == this) {
            QQuickItem::ungrabMouse();

            QMouseEvent ev(*event);
            QCoreApplication::sendEvent(w, &ev);

            m_passthroughGrabbed = NULL;
            QQuickItem* currentGrab = w->mouseGrabberItem();
            if (currentGrab && currentGrab != this) {
                m_passthroughGrabbed = currentGrab;

                if (currentGrab) {
                    connect(currentGrab, SIGNAL(clicked(QQuickMouseEvent*)), SIGNAL(clicked(QQuickMouseEvent*)));
                    connect(currentGrab, SIGNAL(doubleClicked(QQuickMouseEvent*)), SIGNAL(doubleClicked(QQuickMouseEvent*)));
                    connect(currentGrab, SIGNAL(pressAndHold(QQuickMouseEvent*)), SIGNAL(pressAndHold(QQuickMouseEvent*)));

                    connect(currentGrab, SIGNAL(released(QQuickMouseEvent*)), SLOT(onGrabbedReleased(QQuickMouseEvent*)));
                    connect(currentGrab, SIGNAL(canceled()), SLOT(clearConnected()));
                    connect(currentGrab, SIGNAL(canceled()), SIGNAL(canceled()));
                }
            } else if (!currentGrab) {
                // need to re-grab the mouse area
                QQuickMouseArea::grabMouse();
            }
        }

        m_enabledEvents = true;
    }
}

void PassthroughMouseArea::onGrabbedReleased(QQuickMouseEvent* event)
{
    QQuickMouseArea::mouseUngrabEvent();
    Q_EMIT released(event);

    // Needs to be queued, otherwise we will miss the click event.
    QMetaObject::invokeMethod(this, "clearConnected", Qt::QueuedConnection);
}

void PassthroughMouseArea::clearConnected()
{
    if (m_passthroughGrabbed) {
        disconnect(m_passthroughGrabbed, 0, this, 0);
        m_passthroughGrabbed = NULL;
    }
}

void PassthroughMouseArea::mouseUngrabEvent()
{
    if (!m_enabledEvents) {
        return;
    }
    QQuickMouseArea::mouseUngrabEvent();
}
