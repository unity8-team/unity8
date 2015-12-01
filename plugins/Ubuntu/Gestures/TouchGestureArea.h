#ifndef TOUCHGESTUREAREA_H
#define TOUCHGESTUREAREA_H

#include <QQuickItem>

// lib UbuntuGestures
#include <Timer.h>

class TouchOwnershipEvent;
class UnownedTouchEvent;

class GestureTouchPoint : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int pointId READ pointId NOTIFY pointIdChanged)
    Q_PROPERTY(bool pressed READ pressed NOTIFY pressedChanged)
    Q_PROPERTY(qreal x READ x NOTIFY xChanged)
    Q_PROPERTY(qreal y READ y NOTIFY yChanged)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
public:
    GestureTouchPoint()
        : m_id(-1)
        , m_pressed(false)
        , m_x(0)
        , m_y(0)
        , m_dragging(false)
    {
    }

    GestureTouchPoint(const GestureTouchPoint& other)
    : QObject(nullptr)
    {
        m_id = other.pointId();
        m_pressed = other.pressed();
        m_x = other.x();
        m_y = other.y();
        m_dragging = other.dragging();
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

class TouchGestureArea : public QQuickItem
{
    Q_OBJECT

    Q_PROPERTY(QQmlListProperty<GestureTouchPoint> touchPoints READ touchPoints NOTIFY touchPointsUpdated)
    Q_PROPERTY(bool dragging READ dragging NOTIFY draggingChanged)
public:
    // Describes the state of the directional drag gesture.
    enum Status {
        WaitingForTouch,
        Undecided, //Recognizing,
        Recognized,
        Rejected
    };
    TouchGestureArea(QQuickItem* parent = NULL);
    ~TouchGestureArea();

    bool event(QEvent *e) override;

    void setRecognitionTimer(UbuntuGestures::AbstractTimer *timer);

    bool dragging() const;
    QQmlListProperty<GestureTouchPoint> touchPoints();

Q_SIGNALS:
    void statusChanged(Status status);

    void touchPointsUpdated(const QList<GestureTouchPoint*> &touchPoints);
    void draggingChanged(bool dragging);

    void pressed(const QList<GestureTouchPoint*>& points);
    void released(const QList<GestureTouchPoint*>& points);
    void updated(const QList<GestureTouchPoint*>& points);
    void clicked();

private Q_SLOTS:
    void rejectGesture();

private:
    void touchEvent(QTouchEvent *event) override;
    void touchEvent_absent(QTouchEvent *event);
    void touchEvent_undecided(QTouchEvent *event);
    void touchEvent_recognized(QTouchEvent *event);
    void touchEvent_rejected(QTouchEvent *event);

    void touchOwnershipEvent(TouchOwnershipEvent *event);

    void unownedTouchEvent(UnownedTouchEvent *unownedTouchEvent);
    void unownedTouchEvent_undecided(UnownedTouchEvent *unownedTouchEvent);
    void unownedTouchEvent_rejected(UnownedTouchEvent *unownedTouchEvent);

    void processTouchEvents(QTouchEvent *event);
    void addTouchPoint(const QTouchEvent::TouchPoint *tp);
    void updateTouchPoint(GestureTouchPoint *iwtp, const QTouchEvent::TouchPoint *tp);
    void clearTouchLists();
    void setDragging(bool dragging);
    void setStatus(Status newStatus);

    static int touchPoint_count(QQmlListProperty<GestureTouchPoint> *list);
    static GestureTouchPoint* touchPoint_at(QQmlListProperty<GestureTouchPoint> *list, int index);

    Status m_status;
    QVector<int> m_touchCandidates;
    UbuntuGestures::AbstractTimer *m_recognitionTimer;

    bool m_dragging;
    QHash<int, GestureTouchPoint*> m_touchPoints;
    QList<GestureTouchPoint*> m_releasedTouchPoints;
    QList<GestureTouchPoint*> m_pressedTouchPoints;
    QList<GestureTouchPoint*> m_movedTouchPoints;
};

QML_DECLARE_TYPE(GestureTouchPoint)

#endif // TOUCHGESTUREAREA_H
