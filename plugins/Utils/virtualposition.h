#ifndef VIRTUALPOSITION_H
#define VIRTUALPOSITION_H

#include <QObject>
#include <QQmlParserStatus>
#include <QPointer>
#include <QRect>

class QQuickItem;
class QQuickWindow;
class QScreen;

class VirtualPosition : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)

    Q_ENUMS(Direction)
    Q_PROPERTY(Direction direction READ direction WRITE setDirection NOTIFY directionChanged)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool enableWindowChanges READ enableWindowChanges WRITE setEnableWindowChanges NOTIFY enableWindowChangesChanged)

    Q_PROPERTY(int x READ x WRITE setX NOTIFY xChanged)
    Q_PROPERTY(int y READ y WRITE setY NOTIFY yChanged)

    Q_PROPERTY(int mappedX READ mappedX NOTIFY xChanged)
    Q_PROPERTY(int mappedY READ mappedY NOTIFY yChanged)


public:
    VirtualPosition(QObject* parent = 0);
    enum Direction {
        ToDesktop,
        FromDesktop
    };

    void classBegin() override;
    void componentComplete() override;

    Direction direction() const { return m_direction; }
    void setDirection(Direction direction);

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    bool enableWindowChanges() const { return m_enableWindowChanges; }
    void setEnableWindowChanges(bool enable);

    int x() const { return m_x; }
    void setX(int x);
    int y() const { return m_y; }
    void setY(int y);

    int mappedX() const;
    int mappedY() const;

    Q_INVOKABLE QPoint map(const QPoint& pt) const;

Q_SIGNALS:
    void directionChanged();
    void enabledChanged();
    void enableWindowChangesChanged();

    void xChanged();
    void yChanged();
    void windowGeometryChanged(const QRect& windowGeometry);

private Q_SLOTS:
    void emitXChanged();
    void emitYChanged();
    void emitWindowGeometryChanged();

    void updateWindowConnections(QQuickWindow* window);

private:
    QPointer<QQuickWindow> m_window;
    int m_x;
    int m_y;
    Direction m_direction;
    bool m_enabled;
    bool m_enableWindowChanges;
    bool m_complete;
    QRect m_lastWindowGeometry;
};

#endif // VIRTUALPOSITION_H
