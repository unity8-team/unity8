/*
 * Copyright (C) 2014 Canonical, Ltd.
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
 * Author: Daniel d'Andrada <daniel.dandrada@canonical.com>
 */

#include "windowkeysfilter.h"

#include <QQuickWindow>

WindowKeysFilter::WindowKeysFilter(QQuickItem *parent)
    : QQuickItem(parent),
      m_currentEventTimestamp(0)
{
    connect(this, &QQuickItem::windowChanged, this, &WindowKeysFilter::setupFilter);
    connect(this, &QQuickItem::enabledChanged, this, &WindowKeysFilter::setupFilter);
}

bool WindowKeysFilter::eventFilter(QObject *watched, QEvent *event)
{
    if (!isEnabled()) return false;

    Q_ASSERT(!m_filteredWindow.isNull());
    Q_ASSERT(watched == static_cast<QObject*>(m_filteredWindow.data()));
    Q_UNUSED(watched);

    if (event->type() == QEvent::KeyPress || event->type() == QEvent::KeyRelease) {
        // Let QML see this event and decide if it does not want it
        event->accept();

        m_currentEventTimestamp = static_cast<QInputEvent*>(event)->timestamp();
        Q_EMIT currentEventTimestampChanged();

        QCoreApplication::sendEvent(this, event);

        m_currentEventTimestamp = 0;
        Q_EMIT currentEventTimestampChanged();

        return event->isAccepted();
    } else {
        // Not interested
        return false;
    }
}

void WindowKeysFilter::setupFilter()
{
    if (!m_filteredWindow.isNull() == isEnabled() && m_filteredWindow.data() == window()) return;

    if (!m_filteredWindow.isNull()) {
        m_filteredWindow->removeEventFilter(this);
        m_filteredWindow.clear();
    }

    QQuickWindow *wnd = window();
    if (wnd && isEnabled()) {
        wnd->installEventFilter(this);
        m_filteredWindow = wnd;
    }
}

ulong WindowKeysFilter::currentEventTimestamp() const
{
    return m_currentEventTimestamp;
}
