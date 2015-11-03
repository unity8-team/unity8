/*
 * Copyright (C) 2015 Canonical, Ltd.
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
 *
 */

#include "inputwatcher.h"
#include "UnownedTouchEvent.h"

#include <QMouseEvent>
#include <QDebug>

InputWatcher::InputWatcher(QObject *parent)
    : QObject(parent)
    , m_mousePressed(false)
    , m_touchCount(0)
{
}

QObject *InputWatcher::target() const
{
    return m_target;
}

void InputWatcher::setTarget(QObject *value)
{
    if (m_target == value) {
        return;
    }

    if (m_target) {
        m_target->removeEventFilter(this);
    }

    setMousePressed(false);
    setTouchCount(0);

    m_target = value;
    if (m_target) {
        m_target->installEventFilter(this);
    }

    Q_EMIT targetChanged(value);
}

bool InputWatcher::targetPressed() const
{
    return m_mousePressed || m_touchCount > 0;
}

int InputWatcher::touchCount() const
{
    return m_touchCount;
}

bool InputWatcher::eventFilter(QObject* /*watched*/, QEvent *event)
{
    switch (event->type()) {
    case QEvent::TouchBegin:
    case QEvent::TouchEnd:
    case QEvent::TouchUpdate:
        {
            QTouchEvent *touchEvent = static_cast<QTouchEvent*>(event);
            processTouchEvent(touchEvent);
        }
        break;
    case QEvent::MouseButtonPress:
        {
            QMouseEvent *mouseEvent = static_cast<QMouseEvent*>(event);
            if (mouseEvent->button() == Qt::LeftButton) {
                setMousePressed(true);
            }
        }
        break;
    case QEvent::MouseButtonRelease:
        {
            QMouseEvent *mouseEvent = static_cast<QMouseEvent*>(event);
            if (mouseEvent->button() == Qt::LeftButton) {
                setMousePressed(false);
            }
        }
        break;
    default:
        // Process unowned touch events (handles update/release for incomplete gestures)
        if (event->type() == UnownedTouchEvent::unownedTouchEventType()) {
            QTouchEvent* UTE = static_cast<UnownedTouchEvent*>(event)->touchEvent();
            if (UTE) processTouchEvent(UTE);
        }
        // Not interested
        break;
    }

    // We never filter them out. We are just watching.
    return false;
}

void InputWatcher::processTouchEvent(QTouchEvent* event)
{
    int newCount = 0;
    Q_FOREACH(const QTouchEvent::TouchPoint& point, event->touchPoints()) {
        switch(point.state()) {
            case Qt::TouchPointReleased:
                break;
            case Qt::TouchPointPressed:
            case Qt::TouchPointMoved:
            case Qt::TouchPointStationary:
            default:
                newCount++;
                break;
        }
    }
    setTouchCount(newCount);
}

void InputWatcher::setMousePressed(bool value)
{
    if (value == m_mousePressed) {
        return;
    }

    bool oldPressed = targetPressed();
    m_mousePressed = value;
    if (targetPressed() != oldPressed) {
        Q_EMIT targetPressedChanged(targetPressed());
    }
}

void InputWatcher::setTouchCount(int value)
{
    if (m_touchCount != value) {
        bool oldPressed = targetPressed();
        m_touchCount = value;
        Q_EMIT touchCountChanged(m_touchCount);

        if (targetPressed() != oldPressed) {
            Q_EMIT targetPressedChanged(targetPressed());
        }
    }
}
