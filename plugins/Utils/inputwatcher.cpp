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

#include <QDebug>
#include <QGuiApplication>
#include <QStyleHints>
#include <private/qquickwindow_p.h>

InputWatcher::InputWatcher(QObject *parent)
    : QObject(parent)
    , m_dragging(false)
{
}

InputWatcher::~InputWatcher()
{
    clearTouchLists();
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

    if (!m_touchPoints.isEmpty()) {
        clearTouchLists();
        setDragging(false);

        Q_EMIT touchPointsUpdated(QList<InputWatcherTouchPoint*>());
    }

    m_target = value;
    if (m_target) {
        m_target->installEventFilter(this);
    }

    Q_EMIT targetChanged(value);
}

bool InputWatcher::dragging() const
{
    return m_dragging;
}

bool InputWatcher::targetPressed() const
{
    return m_touchPoints.count() > 0;
}

bool InputWatcher::eventFilter(QObject* /*watched*/, QEvent *event)
{
    switch (event->type()) {
    case QEvent::TouchBegin:
    case QEvent::TouchEnd:
    case QEvent::TouchUpdate:
        {
            QTouchEvent *touchEvent = static_cast<QTouchEvent*>(event);
            processTouchPoints(event, touchEvent->touchPoints());

            if (event->type() == QEvent::TouchEnd) {
                setDragging(false);
            }
        }
        break;
    case QEvent::MouseButtonPress:
    case QEvent::MouseButtonRelease:
        {
            QMouseEvent *mouseEvent = static_cast<QMouseEvent*>(event);
            if (mouseEvent->button() != Qt::LeftButton) {
                break;
            }
        }
    case QEvent::MouseMove:
        {
            QMouseEvent *mouseEvent = static_cast<QMouseEvent*>(event);
            m_mouseTouchPoint.setPos(mouseEvent->localPos());
            m_mouseTouchPoint.setScenePos(mouseEvent->windowPos());
            m_mouseTouchPoint.setScreenPos(mouseEvent->screenPos());

            if (event->type() == QEvent::MouseMove)
                m_mouseTouchPoint.setState(Qt::TouchPointMoved);
            else if (event->type() == QEvent::MouseButtonRelease)
                m_mouseTouchPoint.setState(Qt::TouchPointReleased);
            else { // QEvent::MouseButtonPress
                m_mouseTouchPoint.setState(Qt::TouchPointPressed);
            }
            processTouchPoints(mouseEvent, QList<QTouchEvent::TouchPoint>() << m_mouseTouchPoint);

            if (event->type() == QEvent::MouseButtonRelease) {
                setDragging(false);
            }
        }
        break;
    default:
        // Process unowned touch events (handles update/release for incomplete gestures)
        if (event->type() == UnownedTouchEvent::unownedTouchEventType()) {
            QTouchEvent* UTE = static_cast<UnownedTouchEvent*>(event)->touchEvent();
            if (UTE) {
                processTouchPoints(UTE, UTE->touchPoints());

                if (UTE->type() == QEvent::TouchEnd) {
                    setDragging(false);
                }
            }
        }
        // Not interested
        break;
    }

    return false;
}

QQmlListProperty<InputWatcherTouchPoint> InputWatcher::touchPoints()
{
    return QQmlListProperty<InputWatcherTouchPoint>(this,
                                                    0,
                                                    nullptr,
                                                    InputWatcher::touchPoint_count,
                                                    InputWatcher::touchPoint_at,
                                                    0);
}

int InputWatcher::touchPoint_count(QQmlListProperty<InputWatcherTouchPoint> *list)
{
    InputWatcher *q = static_cast<InputWatcher*>(list->object);
    return q->m_touchPoints.count();
}

InputWatcherTouchPoint *InputWatcher::touchPoint_at(QQmlListProperty<InputWatcherTouchPoint> *list, int index)
{
    InputWatcher *q = static_cast<InputWatcher*>(list->object);
    return static_cast<InputWatcherTouchPoint*>((q->m_touchPoints.begin()+index).value());
}

QList<InputWatcherTouchPoint *> InputWatcher::touchPointList() const
{
    return m_touchPoints.values();
}

void InputWatcher::addTouchPoint(QTouchEvent::TouchPoint const* tp)
{
    InputWatcherTouchPoint* iwtp = new InputWatcherTouchPoint();
    iwtp->setPointId(tp->id());
    iwtp->setPressed(true);
    updateTouchPoint(iwtp, tp);
    m_touchPoints.insert(tp->id(), iwtp);
    m_pressedTouchPoints.append(iwtp);
}

void InputWatcher::updateTouchPoint(InputWatcherTouchPoint* iwtp, QTouchEvent::TouchPoint const* tp)
{
    iwtp->setX(tp->pos().x());
    iwtp->setY(tp->pos().y());
}


void InputWatcher::processTouchPoints(QEvent* event, const QList<QTouchEvent::TouchPoint>& touchPoints)
{
    bool added = false;
    bool ended = false;
    bool moved = false;
    bool wantsDrag = false;

    const int dragThreshold = qApp->styleHints()->startDragDistance();
    const int dragVelocity = qApp->styleHints()->startDragVelocity();

    Q_FOREACH(const QTouchEvent::TouchPoint& touchPoint, touchPoints) {
        Qt::TouchPointState touchPointState = touchPoint.state();
        int id = touchPoint.id();

        if (touchPointState & Qt::TouchPointReleased) {
            InputWatcherTouchPoint* iwtp = static_cast<InputWatcherTouchPoint*>(m_touchPoints.value(id));
            if (!iwtp) continue;
            updateTouchPoint(iwtp, &touchPoint);
            iwtp->setPressed(false);
            m_releasedTouchPoints.append(iwtp);
            m_touchPoints.remove(id);
            ended = true;
        }
        else {
            InputWatcherTouchPoint* iwtp = m_touchPoints.value(touchPoint.id(), nullptr);
            if (!iwtp) {
                addTouchPoint(&touchPoint);
                added = true;
            }
            else if (touchPointState & Qt::TouchPointMoved) {
                updateTouchPoint(iwtp, &touchPoint);
                m_movedTouchPoints.append(iwtp);
                moved = true;

                const QPointF &currentPos = touchPoint.scenePos();
                const QPointF &startPos = touchPoint.startScenePos();

                bool overDragThreshold = false;

                switch(event->type()) {
                    case QEvent::TouchBegin:
                    case QEvent::TouchEnd:
                    case QEvent::TouchUpdate:
                    {
                        QTouchEvent* touchEvent = static_cast<QTouchEvent*>(event);
                        bool supportsVelocity = (touchEvent->device()->capabilities() & QTouchDevice::Velocity) && dragVelocity;

                        overDragThreshold |= qAbs(currentPos.x() - startPos.x()) > dragThreshold ||
                                             qAbs(currentPos.y() - startPos.y()) > dragThreshold;
                        if (supportsVelocity) {
                            QVector2D velocityVec = touchPoint.velocity();
                            overDragThreshold |= qAbs(velocityVec.x()) > dragVelocity;
                            overDragThreshold |= qAbs(velocityVec.y()) > dragVelocity;
                        }

                    } break;
                    case QEvent::MouseButtonPress:
                    case QEvent::MouseButtonRelease:
                    case QEvent::MouseMove:
                    {
                        QMouseEvent* mouseEvent = static_cast<QMouseEvent*>(event);
                        overDragThreshold |= QQuickWindowPrivate::dragOverThreshold(currentPos.x() - startPos.x(), Qt::XAxis, mouseEvent, dragThreshold);
                        overDragThreshold |= QQuickWindowPrivate::dragOverThreshold(currentPos.y() - startPos.y(), Qt::YAxis, mouseEvent, dragThreshold);
                    } break;
                    default:
                        break;
                }

                if (overDragThreshold) {
                    iwtp->setDragging(true);
                    wantsDrag = true;
                }
            }
            else {
                updateTouchPoint(iwtp, &touchPoint);
            }
        }
    }

    if (wantsDrag && !dragging()) {
        setDragging(true);
    }

    if (!dragging() && m_touchPoints.isEmpty()) Q_EMIT clicked();
    if (ended) Q_EMIT released(m_releasedTouchPoints);
    if (added) Q_EMIT pressed(m_pressedTouchPoints);
    if (moved) Q_EMIT updated(m_movedTouchPoints);
    if (added || ended || moved) Q_EMIT touchPointsUpdated(m_touchPoints.values());
}

void InputWatcher::clearTouchLists()
{
    Q_FOREACH (InputWatcherTouchPoint *iwtp, m_releasedTouchPoints) {
        delete iwtp;
    }
    qDeleteAll(m_touchPoints);
    m_touchPoints.clear();
    m_releasedTouchPoints.clear();
    m_pressedTouchPoints.clear();
    m_movedTouchPoints.clear();
}

void InputWatcher::setDragging(bool dragging)
{
    if (m_dragging == dragging)
        return;
    m_dragging = dragging;
    Q_EMIT draggingChanged(m_dragging);
}

void InputWatcherTouchPoint::setPointId(int id)
{
    if (m_id == id)
        return;
    m_id = id;
    Q_EMIT pointIdChanged();
}

void InputWatcherTouchPoint::setPressed(bool pressed)
{
    if (m_pressed == pressed)
        return;
    m_pressed = pressed;
    Q_EMIT pressedChanged();
}

void InputWatcherTouchPoint::setX(qreal x)
{
    if (m_x == x)
        return;
    m_x = x;
    Q_EMIT xChanged();
}

void InputWatcherTouchPoint::setY(qreal y)
{
    if (m_y == y)
        return;
    m_y = y;
    Q_EMIT yChanged();
}

void InputWatcherTouchPoint::setDragging(bool dragging)
{
    if (m_dragging == dragging)
        return;

    m_dragging = dragging;
    Q_EMIT draggingChanged();
}
