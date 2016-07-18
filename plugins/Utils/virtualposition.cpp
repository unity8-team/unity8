#include "virtualposition.h"

#include <QQuickItem>
#include <QScreen>
#include <QQuickWindow>

VirtualPosition::VirtualPosition(QObject *parent)
    : QObject(parent)
    , m_enabled(true)
    , m_enableWindowChanges(true)
    , m_complete(false)
{
}

void VirtualPosition::componentComplete()
{
    if (auto screenItem = qobject_cast<QQuickItem*>(parent())) {
        // connect to window geometry & screen changes
        auto updateWindow = [this/*, updateScreen*/](QQuickWindow* window) {
            updateWindowConnections(window);
            if (m_complete && m_enableWindowChanges) {
                emitPositionChanged();
            }
        };
        connect(screenItem, &QQuickItem::windowChanged, this, updateWindow);
        updateWindow(screenItem->window());
    }
    m_complete = true;
    emitPositionChanged();
}

void VirtualPosition::setEnabled(bool enabled)
{
    if (m_enabled != enabled) {
        return;
    }

    m_enabled = enabled;
    Q_EMIT enabledChanged();
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

void VirtualPosition::setPosition(const QPoint &pt)
{
    if (m_pt == pt) {
        return;
    }

    m_pt = pt;
    emitPositionChanged();
}

QPoint VirtualPosition::mappedToDesktop() const
{
    if (!m_window) return m_pt;
    return m_window->geometry().topLeft() + m_pt;
}

QPoint VirtualPosition::mappedFromDesktop() const
{
    if (!m_window) return m_pt;
    return m_pt - m_window->geometry().topLeft();
}

void VirtualPosition::emitPositionChanged()
{
    if (!m_complete || !m_enabled) return;

    Q_EMIT positionChanged();
}

void VirtualPosition::updateWindowConnections(QQuickWindow *window)
{
    if (window) disconnect(window, 0, this, 0);

    m_window = window;

    if (window && m_enableWindowChanges) {
        connect(window, &QQuickWindow::xChanged, this, &VirtualPosition::emitPositionChanged);
        connect(window, &QQuickWindow::yChanged, this, &VirtualPosition::emitPositionChanged);
        connect(window, &QQuickWindow::screenChanged, this, &VirtualPosition::emitPositionChanged);
    }
}
