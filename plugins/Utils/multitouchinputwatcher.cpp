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

#include "multitouchinputwatcher.h"
#include "inputwatcher.h"
#include "UnownedTouchEvent.h"

#include <QTimer>
#include <QTouchEvent>

class InputWatcherWrapped : public InputWatcher
{
public:
    InputWatcherWrapped(MultiTouchInputWatcher* multiTouchInputWatcher)
        : InputWatcher(multiTouchInputWatcher)
        , m_multiTouchInputWatcher(multiTouchInputWatcher)
    {
    }

    bool eventFilter(QObject* watched, QEvent *event)
    {
        bool ret = InputWatcher::eventFilter(watched, event);

        switch (event->type()) {
        case QEvent::TouchBegin:
        case QEvent::TouchEnd:
        case QEvent::TouchUpdate:
            {
                QTouchEvent *touchEvent = static_cast<QTouchEvent*>(event);
                if (touchEvent->touchPointStates() & (Qt::TouchPointMoved|Qt::TouchPointPressed)) {
                    return m_multiTouchInputWatcher->isPressed();
                }
            }
            break;
        case QEvent::MouseButtonRelease:
            break;
        case QEvent::MouseButtonPress:
        case QEvent::MouseMove:
            {
                return m_multiTouchInputWatcher->isPressed();
            }
            break;
        default:
            // Process unowned touch events (handles update/release for incomplete gestures)
            if (event->type() == UnownedTouchEvent::unownedTouchEventType()) {
                QTouchEvent* UTE = static_cast<UnownedTouchEvent*>(event)->touchEvent();
                if (UTE && UTE->touchPointStates() & (Qt::TouchPointMoved|Qt::TouchPointPressed)) {
                    return true;
                }
            }
            // Not interested
            break;
        }

        return ret;
    }

private:
    MultiTouchInputWatcher* m_multiTouchInputWatcher;
};

MultiTouchInputWatcher::MultiTouchInputWatcher(QObject *parent)
    : QObject(parent)
    , m_inputWatcher(new InputWatcherWrapped(this))
    , m_multiTouchCount(1)
    , m_pressed(false)
    , m_dragging(false)
    , m_releaseTimer(new QTimer(this))
{
    connect(m_inputWatcher, &InputWatcher::targetChanged, this, [this](QObject* value) {
        setDragging(false);
        setPressed(false);
        Q_EMIT targetChanged(value);
    });

    connect(m_inputWatcher, &InputWatcher::touchPointsUpdated, this, [this](const QList<InputWatcherTouchPoint*> &touchPoints) {

        qDebug() << "TOUCH POINTS" << touchPoints;

        if (m_releaseTimer->isActive()) {
            m_touchUpdated = true;
            updateTouchPoints(touchPoints);
            Q_EMIT touchPointsUpdated(m_cachedPoints);
        } else {
            // cache the last updated points.
            qDeleteAll(m_cachedPoints);
            m_cachedPoints.clear();
            updateTouchPoints(touchPoints);
            Q_EMIT touchPointsUpdated(m_cachedPoints);
        }
    });

    connect(m_inputWatcher, &InputWatcher::pressed, this, [this]() {
        auto touchPoints = m_inputWatcher->touchPoints();
        int count = m_inputWatcher->touchPoint_count(&touchPoints);
        if (count == multiTouchCount()) {
            m_releaseTimer->stop();
            setPressed(true);
        } else {
            setPressed(false);
        }
    });

    connect(m_inputWatcher, &InputWatcher::released, this, [this]() {
        auto touchPoints = m_inputWatcher->touchPoints();
        int count = m_inputWatcher->touchPoint_count(&touchPoints);
        if (isPressed() && count == 0) {
            m_releaseTimer->start(100);
        }
    });

    connect(m_inputWatcher, &InputWatcher::clicked, this, [this]() {
        auto touchPoints = m_inputWatcher->touchPoints();
        qDebug() << "InputWatcher::clicked";
        int count = m_inputWatcher->touchPoint_count(&touchPoints);
        if (count == 0) {
            if (isPressed()) {
                Q_EMIT clicked();
            }
        }
    });

    connect(m_inputWatcher, &InputWatcher::draggingChanged, this, [this]() {
        if (isPressed() && m_inputWatcher->dragging()) {
            setDragging(true);
        }
    });

    connect(m_releaseTimer, &QTimer::timeout, this, [this]() {
        if (isDragging()) {
            Q_EMIT dropped();
        }
        setDragging(false);
        setPressed(false);

        if (m_touchUpdated) {
            // cache the last updated points.
            qDeleteAll(m_cachedPoints);
            m_cachedPoints.clear();
            auto pointList = m_inputWatcher->touchPointList();
            Q_FOREACH(InputWatcherTouchPoint* point, pointList) {
                m_cachedPoints.append(new InputWatcherTouchPoint(*point));
            }

            m_touchUpdated = false;
            Q_EMIT touchPointsUpdated(m_cachedPoints);
        }

    }, Qt::DirectConnection);
}

MultiTouchInputWatcher::~MultiTouchInputWatcher()
{
}

QObject *MultiTouchInputWatcher::target() const
{
    return m_inputWatcher->target();
}

void MultiTouchInputWatcher::setTarget(QObject *value)
{
    m_inputWatcher->setTarget(value);
}

bool MultiTouchInputWatcher::isPressed() const
{
    return m_pressed;
}

void MultiTouchInputWatcher::setPressed(bool isPressed)
{
    if (m_pressed == isPressed)
        return;
    m_pressed = isPressed;
    Q_EMIT pressedChanged(m_pressed);
    if (m_pressed) {
        Q_EMIT pressed();
    } else {
        Q_EMIT released();
    }
}

bool MultiTouchInputWatcher::isDragging() const
{
    return m_dragging;
}

QQmlListProperty<InputWatcherTouchPoint> MultiTouchInputWatcher::touchPoints()
{
    return QQmlListProperty<InputWatcherTouchPoint>(this, m_cachedPoints);
}

void MultiTouchInputWatcher::setDragging(bool dragging)
{
    if (m_dragging == dragging)
        return;
    m_dragging = dragging;
    Q_EMIT draggingChanged(m_dragging);
}

int MultiTouchInputWatcher::multiTouchCount() const
{
    return m_multiTouchCount;
}

void MultiTouchInputWatcher::setMultiTouchCount(int count)
{
    if (m_multiTouchCount == count)
        return;
    m_multiTouchCount = count;
    Q_EMIT multiTouchCountChanged(count);
}

void MultiTouchInputWatcher::updateTouchPoints(const QList<InputWatcherTouchPoint*> &touchPoints)
{
    QList<InputWatcherTouchPoint*> newPoints;
    Q_FOREACH(InputWatcherTouchPoint* existingPoint, touchPoints) {
        bool found = false;
        Q_FOREACH(InputWatcherTouchPoint* updatedPoint, m_cachedPoints) {
            if (existingPoint->pointId() == updatedPoint->pointId()) {
                existingPoint->setX(updatedPoint->x());
                existingPoint->setY(updatedPoint->y());
                existingPoint->setDragging(updatedPoint->dragging());
                found = true;
            }
        }
        if (!found) {
            newPoints.append(new InputWatcherTouchPoint(*existingPoint));
        }
    }
    m_cachedPoints.append(newPoints);
}
