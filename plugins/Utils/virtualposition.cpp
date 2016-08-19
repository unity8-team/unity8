#include "virtualposition.h"

#include <QQuickItem>
#include <QScreen>
#include <QQuickWindow>

VirtualPosition::VirtualPosition(QObject *parent)
    : QObject(parent)
    , m_x(0)
    , m_y(0)
    , m_direction(ToDesktop)
    , m_enabled(true)
    , m_enableWindowChanges(true)
    , m_complete(false)
{
}

void VirtualPosition::classBegin()
{
    if (auto screenItem = qobject_cast<QQuickItem*>(parent())) {
        // connect to window geometry & screen changes
        auto updateWindow = [this/*, updateScreen*/](QQuickWindow* window) {
            updateWindowConnections(window);
        };
        connect(screenItem, &QQuickItem::windowChanged, this, updateWindow);
        updateWindow(screenItem->window());
    }
}

void VirtualPosition::componentComplete()
{
    m_complete = true;
}

void VirtualPosition::setDirection(VirtualPosition::Direction direction)
{
    if (m_direction == direction) {
        return;
    }

    m_direction = direction;
    Q_EMIT directionChanged();
}

void VirtualPosition::setEnabled(bool enabled)
{
    if (m_enabled == enabled) {
        return;
    }

    m_enabled = enabled;
    Q_EMIT enabledChanged();

    if (m_enabled) {
        emitXChanged();
        Q_EMIT yChanged();
    }
}

void VirtualPosition::setEnableWindowChanges(bool enable)
{
    if (m_enableWindowChanges == enable) {
        return;
    }

    m_enableWindowChanges = enable;
    updateWindowConnections(m_window);

    Q_EMIT enableWindowChangesChanged();
}

void VirtualPosition::setX(int x)
{
    if (m_x == x) {
        return;
    }

    m_x = x;
    emitXChanged();
}

void VirtualPosition::setY(int y)
{
    if (m_y == y) {
        return;
    }

    m_y = y;
    emitYChanged();
}

int VirtualPosition::mappedX() const
{
    if (!m_window) return m_x;

    if (m_direction == ToDesktop) {
        return m_window->geometry().left() + m_x;
    } else {
        return m_x - m_window->geometry().left();
    }
}

int VirtualPosition::mappedY() const
{
    if (!m_window) return m_y;

    if (m_direction == ToDesktop) {
        return m_window->geometry().top() + m_y;
    } else {
        return m_y - m_window->geometry().top();
    }
}

QPoint VirtualPosition::map(const QPoint &pt) const
{
    if (!m_window) return pt;

    if (m_direction == ToDesktop) {
        return m_window->geometry().topLeft() + pt;
    } else {
        return pt - m_window->geometry().topLeft();
    }
}

void VirtualPosition::emitXChanged()
{
    if (!m_complete || !m_enabled) return;
    Q_EMIT xChanged();
}

void VirtualPosition::emitYChanged()
{
    if (!m_complete || !m_enabled) return;
    Q_EMIT yChanged();
}


void VirtualPosition::emitWindowGeometryChanged()
{
    if (!m_complete || !m_enabled) return;

    if (m_enableWindowChanges && m_window) {
        if (m_window->geometry() != m_lastWindowGeometry) {
            m_lastWindowGeometry = m_window->geometry();
            Q_EMIT windowGeometryChanged(m_lastWindowGeometry);
        }
    }
}

void VirtualPosition::updateWindowConnections(QQuickWindow *window)
{
    if (window) disconnect(window, 0, this, 0);

    m_window = window;

    if (window && m_enableWindowChanges) {
        m_lastWindowGeometry = window->geometry();

        connect(window, &QQuickWindow::xChanged, this, &VirtualPosition::emitWindowGeometryChanged);
        connect(window, &QQuickWindow::yChanged, this, &VirtualPosition::emitWindowGeometryChanged);
        connect(window, &QQuickWindow::widthChanged, this, &VirtualPosition::emitWindowGeometryChanged);
        connect(window, &QQuickWindow::heightChanged, this, &VirtualPosition::emitWindowGeometryChanged);
        connect(window, &QQuickWindow::screenChanged, this, &VirtualPosition::emitWindowGeometryChanged);
    }
}
