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

#ifndef UNITY_MULTITOUCHINPUTWATCHER_H
#define UNITY_MULTITOUCHINPUTWATCHER_H

#include <QObject>
#include <QPointer>
#include <QQmlListProperty>
#include <QTouchEvent>
#include <QtQml>
class QTimer;

#include "inputwatcher.h"

class MultiTouchInputWatcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* target READ target WRITE setTarget NOTIFY targetChanged)

    Q_PROPERTY(QQmlListProperty<InputWatcherTouchPoint> touchPoints READ touchPoints NOTIFY touchPointsUpdated)
    Q_PROPERTY(int multiTouchCount READ multiTouchCount WRITE setMultiTouchCount NOTIFY multiTouchCountChanged)
    Q_PROPERTY(bool pressed READ isPressed NOTIFY pressedChanged)
    Q_PROPERTY(bool dragging READ isDragging NOTIFY draggingChanged)
public:
    MultiTouchInputWatcher(QObject *parent = nullptr);
    virtual ~MultiTouchInputWatcher();

    QObject *target() const;
    void setTarget(QObject *value);

    int multiTouchCount() const;
    void setMultiTouchCount(int count);

    bool isPressed() const;
    bool isDragging() const;

    QQmlListProperty<InputWatcherTouchPoint> touchPoints();

Q_SIGNALS:
    void targetChanged(QObject *value);
    void touchPointsUpdated(const QList<InputWatcherTouchPoint*> &touchPoints);
    void pressedChanged(bool pressed);
    void draggingChanged(bool dragging);
    void multiTouchCountChanged(int count);

    void pressed();
    void released();
    void updated();
    void clicked();
    void dropped();

private:
    void setPressed(bool pressed);
    void setDragging(bool dragging);
    void updateTouchPoints(const QList<InputWatcherTouchPoint *> &touchPoints);

    InputWatcher* m_inputWatcher;
    int m_multiTouchCount;
    bool m_pressed;
    bool m_dragging;
    QTimer* m_releaseTimer;
    bool m_touchUpdated;
    QList<InputWatcherTouchPoint *> m_cachedPoints;
};

#endif // UNITY_INPUTWATCHER_H
