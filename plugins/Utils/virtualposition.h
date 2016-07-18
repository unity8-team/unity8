#ifndef VIRTUALPOSITION_H
#define VIRTUALPOSITION_H

#include <QObject>
#include <QQmlParserStatus>
#include <QPointer>
#include <QPoint>

class QQuickItem;
class QQuickWindow;
class QScreen;

class VirtualPosition : public QObject, public QQmlParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)


    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool enableWindowChanges READ enableWindowChanges WRITE setEnableWindowChanges NOTIFY enableWindowChangesChanged)
    Q_PROPERTY(QPoint position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(QPoint mappedToDesktop READ mappedToDesktop NOTIFY positionChanged)
    Q_PROPERTY(QPoint mappedFromDesktop READ mappedFromDesktop NOTIFY positionChanged)

public:
    VirtualPosition(QObject* parent = 0);

    void classBegin() override {}
    void componentComplete() override;

    bool enabled() const { return m_enabled; }
    void setEnabled(bool enabled);

    bool enableWindowChanges() const { return m_enableWindowChanges; }
    void setEnableWindowChanges(bool enable);

    QPoint position() const { return m_pt; }
    void setPosition(const QPoint& pt);

    QPoint mappedToDesktop() const;
    QPoint mappedFromDesktop() const;

Q_SIGNALS:
    void enabledChanged();
    void positionChanged();
    void enableWindowChangesChanged();

private Q_SLOTS:
    void emitPositionChanged();

    void updateWindowConnections(QQuickWindow* window);

private:
    QPoint m_pt;
    QPointer<QQuickWindow> m_window;
    bool m_enabled;
    bool m_enableWindowChanges;
    bool m_complete;
};

#endif // VIRTUALPOSITION_H
