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

#ifndef UNITY_INPUTWATCHER_H
#define UNITY_INPUTWATCHER_H

#include <QObject>
#include <QPointer>
#include <QQmlListProperty>
#include <QTouchEvent>
#include <QtQml>

class InputWatcherTouchPoint : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int pointId READ pointId NOTIFY pointIdChanged)
    Q_PROPERTY(bool pressed READ pressed NOTIFY pressedChanged)
    Q_PROPERTY(qreal x READ x NOTIFY xChanged)
    Q_PROPERTY(qreal y READ y NOTIFY yChanged)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
public:
    InputWatcherTouchPoint()
        : m_id(-1)
        , m_pressed(false)
        , m_x(0)
        , m_y(0)
        , m_dragging(false)
    {
    }

    int pointId() const { return m_id; }
    void setPointId(int id);

    bool pressed() const { return m_pressed; }
    void setPressed(bool pressed);

    qreal x() const { return m_x; }
    void setX(qreal x);

    qreal y() const { return m_y; }
    void setY(qreal y);

    bool dragging() const { return m_dragging; }
    void setDragging(bool dragging);


Q_SIGNALS:
    void pointIdChanged();
    void pressedChanged();
    void xChanged();
    void yChanged();
    void draggingChanged();

private:
    int m_id;
    bool m_pressed;
    qreal m_x;
    qreal m_y;
    bool m_dragging;
};

/*
  Monitors the target object for input events to figure out whether it's pressed
  or not.
 */
class InputWatcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* target READ target WRITE setTarget NOTIFY targetChanged)

    // Whether the target object is pressed (by either touch or mouse)
    Q_PROPERTY(QQmlListProperty<InputWatcherTouchPoint> touchPoints READ touchPoints NOTIFY touchPointsUpdated)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
    Q_PROPERTY(bool eatMoveEvents READ eatMoveEvents WRITE setEatMoveEvents NOTIFY eatMoveEventsChanged)
public:
    InputWatcher(QObject *parent = nullptr);
    virtual ~InputWatcher();

    QObject *target() const;
    void setTarget(QObject *value);

    bool dragging() const;

    bool eatMoveEvents() const;
    void setEatMoveEvents(bool eatMoveEvents);

    bool targetPressed() const;

    bool eventFilter(QObject *watched, QEvent *event) override;

    QQmlListProperty<InputWatcherTouchPoint> touchPoints();

    static int touchPoint_count(QQmlListProperty<InputWatcherTouchPoint> *list);

    static InputWatcherTouchPoint* touchPoint_at(QQmlListProperty<InputWatcherTouchPoint> *list, int index);

Q_SIGNALS:
    void targetChanged(QObject *value);
    void touchPointsUpdated(const QList<InputWatcherTouchPoint*> &touchPoints);
    void draggingChanged(bool dragging);
    void eatMoveEventsChanged();

    void pressed(const QList<InputWatcherTouchPoint*>& points);
    void released(const QList<InputWatcherTouchPoint*>& points);
    void updated(const QList<InputWatcherTouchPoint*>& points);

private:
    bool processTouchPoints(const QList<QTouchEvent::TouchPoint>& points);
    void addTouchPoint(const QTouchEvent::TouchPoint *tp);
    void updateTouchPoint(InputWatcherTouchPoint *iwtp, const QTouchEvent::TouchPoint *tp);
    void clearTouchLists();
    void setDragging(bool dragging);

    QHash<int, InputWatcherTouchPoint*> m_touchPoints;
    QTouchEvent::TouchPoint m_mouseTouchPoint;
    QPointer<QObject> m_target;
    bool m_eatMoveEvents;
    bool m_dragging;

    QList<InputWatcherTouchPoint*> m_releasedTouchPoints;
    QList<InputWatcherTouchPoint*> m_pressedTouchPoints;
    QList<InputWatcherTouchPoint*> m_movedTouchPoints;
};

QML_DECLARE_TYPE(InputWatcherTouchPoint)

#endif // UNITY_INPUTWATCHER_H
